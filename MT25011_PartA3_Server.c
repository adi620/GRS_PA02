#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/socket.h>
#include <sys/uio.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <linux/errqueue.h>
#include <time.h>
#include <errno.h>
#include <poll.h>

#define MAX_CLIENTS 100
#define NUM_FIELDS 8

typedef struct {
    char *field[NUM_FIELDS];
} Message;

int message_size = 1024;
volatile int keep_running = 1;

Message* create_message(int size) {
    Message *msg = (Message*)malloc(sizeof(Message));
    if (!msg) return NULL;
    
    int field_size = size / NUM_FIELDS;
    for (int i = 0; i < NUM_FIELDS; i++) {
        msg->field[i] = (char*)malloc(field_size);
        if (!msg->field[i]) {
            for (int j = 0; j < i; j++) free(msg->field[j]);
            free(msg);
            return NULL;
        }
        memset(msg->field[i], 'A' + i, field_size - 1);
        msg->field[i][field_size - 1] = '\0';
    }
    return msg;
}

void free_message(Message *msg) {
    if (!msg) return;
    for (int i = 0; i < NUM_FIELDS; i++) free(msg->field[i]);
    free(msg);
}

// Updated to return the actual number of reaped completions
int handle_zerocopy_completions(int sock) {
    char control[100];
    struct msghdr msg = {0};
    msg.msg_control = control;
    msg.msg_controllen = sizeof(control);
    
    int ret = recvmsg(sock, &msg, MSG_ERRQUEUE);
    if (ret < 0) return 0;
    
    struct cmsghdr *cm;
    for (cm = CMSG_FIRSTHDR(&msg); cm; cm = CMSG_NXTHDR(&msg, cm)) {
        if (cm->cmsg_level == SOL_IP && cm->cmsg_type == IP_RECVERR) {
            struct sock_extended_err *serr = (struct sock_extended_err *)CMSG_DATA(cm);
            if (serr->ee_origin == SO_EE_ORIGIN_ZEROCOPY) {
                // Return the range of completed sequence numbers
                return (serr->ee_data - serr->ee_info + 1);
            }
        }
    }
    return 0;
}

void* handle_client(void *arg) {
    int client_sock = *(int*)arg;
    free(arg);
    
    int optval = 1;
    setsockopt(client_sock, SOL_SOCKET, SO_ZEROCOPY, &optval, sizeof(optval));
    
    Message *msg = create_message(message_size);
    int field_size = message_size / NUM_FIELDS;
    
    struct iovec iov[NUM_FIELDS];
    for (int i = 0; i < NUM_FIELDS; i++) {
        iov[i].iov_base = msg->field[i];
        iov[i].iov_len = field_size;
    }
    
    struct msghdr msghdr = {0};
    msghdr.msg_iov = iov;
    msghdr.msg_iovlen = NUM_FIELDS;
    
    unsigned long send_count = 0;
    unsigned long completion_count = 0;
    
    while (keep_running) {
        ssize_t sent = sendmsg(client_sock, &msghdr, MSG_ZEROCOPY);
        if (sent < 0) {
            if (errno == ENOBUFS) {
                completion_count += handle_zerocopy_completions(client_sock);
                continue;
            }
            if (errno == EPIPE || errno == ECONNRESET) break;
        } else {
            send_count++;
        }
        
        if (send_count % 100 == 0) {
            completion_count += handle_zerocopy_completions(client_sock);
        }
    }
    
    // Fixed: Added POLLERR to events
    struct pollfd pfd = { .fd = client_sock, .events = POLLERR };
    while (completion_count < send_count) {
        if (poll(&pfd, 1, 100) > 0) {
            completion_count += handle_zerocopy_completions(client_sock);
        } else {
            break; 
        }
    }
    
    free_message(msg);
    close(client_sock);
    return NULL;
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <port> <message_size>\n", argv[0]);
        exit(EXIT_FAILURE);
    }
    
    int port = atoi(argv[1]);
    message_size = atoi(argv[2]);
    
    int server_sock = socket(AF_INET, SOCK_STREAM, 0);
    int opt = 1;
    setsockopt(server_sock, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    
    struct sockaddr_in server_addr = {0};
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(port);
    
    bind(server_sock, (struct sockaddr*)&server_addr, sizeof(server_addr));
    listen(server_sock, MAX_CLIENTS);
    
    printf("[Server A3] Listening on port %d, size %d...\n", port, message_size);
    
    while (keep_running) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        int *client_sock = malloc(sizeof(int));
        *client_sock = accept(server_sock, (struct sockaddr*)&client_addr, &client_len);
        
        if (*client_sock >= 0) {
            pthread_t thread;
            pthread_create(&thread, NULL, handle_client, client_sock);
            pthread_detach(thread);
        } else {
            free(client_sock);
        }
    }
    
    close(server_sock);
    return 0;
}