/*
 * MT25011 - Replace XXX with your roll number
 * PA02 - Part A3: Zero-Copy Implementation (Server)
 * Uses sendmsg() with MSG_ZEROCOPY flag (eliminates both copies)
 */

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

// Message structure with 8 dynamically allocated string fields
typedef struct {
    char *field[NUM_FIELDS];
} Message;

// Global parameters
int message_size = 1024;
volatile int keep_running = 1;

// Initialize message structure
Message* create_message(int size) {
    Message *msg = (Message*)malloc(sizeof(Message));
    if (!msg) return NULL;
    
    int field_size = size / NUM_FIELDS;
    for (int i = 0; i < NUM_FIELDS; i++) {
        msg->field[i] = (char*)malloc(field_size);
        if (!msg->field[i]) {
            for (int j = 0; j < i; j++) {
                free(msg->field[j]);
            }
            free(msg);
            return NULL;
        }
        memset(msg->field[i], 'A' + i, field_size - 1);
        msg->field[i][field_size - 1] = '\0';
    }
    return msg;
}

// Free message structure
void free_message(Message *msg) {
    if (!msg) return;
    for (int i = 0; i < NUM_FIELDS; i++) {
        free(msg->field[i]);
    }
    free(msg);
}

// Handle zero-copy completion notifications
int handle_zerocopy_completions(int sock) {
    char control[100];
    struct msghdr msg = {};
    msg.msg_control = control;
    msg.msg_controllen = sizeof(control);
    
    int ret = recvmsg(sock, &msg, MSG_ERRQUEUE);
    if (ret < 0) {
        if (errno == EAGAIN || errno == EWOULDBLOCK) {
            return 0; // No completions available
        }
        return -1;
    }
    
    struct cmsghdr *cm;
    for (cm = CMSG_FIRSTHDR(&msg); cm; cm = CMSG_NXTHDR(&msg, cm)) {
        if (cm->cmsg_level == SOL_IP && cm->cmsg_type == IP_RECVERR) {
            struct sock_extended_err *serr = (struct sock_extended_err *)CMSG_DATA(cm);
            if (serr->ee_origin == SO_EE_ORIGIN_ZEROCOPY) {
                // Zero-copy transmission completed
                return 1;
            }
        }
    }
    return 0;
}

// Client handler thread
void* handle_client(void *arg) {
    int client_sock = *(int*)arg;
    free(arg);
    
    // Enable zero-copy on socket
    int optval = 1;
    if (setsockopt(client_sock, SOL_SOCKET, SO_ZEROCOPY, &optval, sizeof(optval)) < 0) {
        perror("setsockopt SO_ZEROCOPY");
        close(client_sock);
        return NULL;
    }
    
    Message *msg = create_message(message_size);
    if (!msg) {
        close(client_sock);
        return NULL;
    }
    
    int field_size = message_size / NUM_FIELDS;
    
    // Setup iovec for scatter-gather I/O
    struct iovec iov[NUM_FIELDS];
    for (int i = 0; i < NUM_FIELDS; i++) {
        iov[i].iov_base = msg->field[i];
        iov[i].iov_len = field_size;
    }
    
    struct msghdr msghdr;
    memset(&msghdr, 0, sizeof(msghdr));
    msghdr.msg_iov = iov;
    msghdr.msg_iovlen = NUM_FIELDS;
    
    unsigned long send_count = 0;
    unsigned long completion_count = 0;
    
    // Continuously send messages using MSG_ZEROCOPY - ZERO COPY PATH
    // Kernel directly uses user-space buffer pages (via get_user_pages)
    // NIC DMA reads directly from these pages to network
    // No intermediate copies in user or kernel space
    // Completion notifications ensure buffers aren't reused prematurely
    while (keep_running) {
        ssize_t sent = sendmsg(client_sock, &msghdr, MSG_ZEROCOPY);
        if (sent < 0) {
            if (errno == EPIPE || errno == ECONNRESET) {
                break;
            }
            if (errno == ENOBUFS) {
                // Too many outstanding sends, wait for completions
                handle_zerocopy_completions(client_sock);
                continue;
            }
        } else {
            send_count++;
        }
        
        // Periodically check for completions to avoid buffer exhaustion
        if (send_count % 1000 == 0) {
            handle_zerocopy_completions(client_sock);
        }
    }
    
    // Wait for remaining completions before cleanup
    struct pollfd pfd = { .fd = client_sock, .events = 0 };
    while (completion_count < send_count) {
        if (poll(&pfd, 1, 100) > 0) {
            if (handle_zerocopy_completions(client_sock) > 0) {
                completion_count++;
            }
        } else {
            break; // Timeout, proceed with cleanup
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
    
    printf("[Server A3] Starting zero-copy server on port %d\n", port);
    printf("[Server A3] Message size: %d bytes\n", message_size);
    
    int server_sock = socket(AF_INET, SOCK_STREAM, 0);
    if (server_sock < 0) {
        perror("socket");
        exit(EXIT_FAILURE);
    }
    
    int opt = 1;
    setsockopt(server_sock, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(port);
    
    if (bind(server_sock, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("bind");
        close(server_sock);
        exit(EXIT_FAILURE);
    }
    
    if (listen(server_sock, MAX_CLIENTS) < 0) {
        perror("listen");
        close(server_sock);
        exit(EXIT_FAILURE);
    }
    
    printf("[Server A3] Listening for connections...\n");
    
    while (keep_running) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        
        int *client_sock = (int*)malloc(sizeof(int));
        *client_sock = accept(server_sock, (struct sockaddr*)&client_addr, &client_len);
        
        if (*client_sock < 0) {
            free(client_sock);
            continue;
        }
        
        printf("[Server A3] Client connected: %s:%d\n", 
               inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port));
        
        pthread_t thread;
        pthread_create(&thread, NULL, handle_client, client_sock);
        pthread_detach(thread);
    }
    
    close(server_sock);
    return 0;
}
