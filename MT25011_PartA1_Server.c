/*
 * MT25011 - Replace XXX with your roll number
 * PA02 - Part A1: Two-Copy Implementation (Server)
 * Uses send() socket primitive (baseline with two copies)
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <time.h>
#include <errno.h>

#define MAX_CLIENTS 100
#define NUM_FIELDS 8
#define FIELD_SIZE 256

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
            // Free previously allocated fields on error
            for (int j = 0; j < i; j++) {
                free(msg->field[j]);
            }
            free(msg);
            return NULL;
        }
        // Fill with sample data
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

// Serialize message for transmission
char* serialize_message(Message *msg, int size, int *total_size) {
    int field_size = size / NUM_FIELDS;
    *total_size = size;
    
    char *buffer = (char*)malloc(size);
    if (!buffer) return NULL;
    
    char *ptr = buffer;
    for (int i = 0; i < NUM_FIELDS; i++) {
        memcpy(ptr, msg->field[i], field_size);
        ptr += field_size;
    }
    
    return buffer;
}

// Client handler thread
void* handle_client(void *arg) {
    int client_sock = *(int*)arg;
    free(arg);
    
    Message *msg = create_message(message_size);
    if (!msg) {
        close(client_sock);
        return NULL;
    }
    
    int total_size;
    char *buffer = serialize_message(msg, message_size, &total_size);
    if (!buffer) {
        free_message(msg);
        close(client_sock);
        return NULL;
    }
    
    // Continuously send messages using send() - TWO COPY PATH
    // Copy 1: User space buffer to kernel socket buffer
    // Copy 2: Kernel socket buffer to NIC
    while (keep_running) {
        ssize_t sent = send(client_sock, buffer, total_size, 0);
        if (sent < 0) {
            if (errno == EPIPE || errno == ECONNRESET) {
                break;
            }
        }
    }
    
    free(buffer);
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
    
    printf("[Server A1] Starting two-copy server on port %d\n", port);
    printf("[Server A1] Message size: %d bytes\n", message_size);
    
    int server_sock = socket(AF_INET, SOCK_STREAM, 0);
    if (server_sock < 0) {
        perror("socket");
        exit(EXIT_FAILURE);
    }
    
    // Set socket options
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
    
    printf("[Server A1] Listening for connections...\n");
    
    // Accept clients and spawn threads
    while (keep_running) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        
        int *client_sock = (int*)malloc(sizeof(int));
        *client_sock = accept(server_sock, (struct sockaddr*)&client_addr, &client_len);
        
        if (*client_sock < 0) {
            free(client_sock);
            continue;
        }
        
        printf("[Server A1] Client connected: %s:%d\n", 
               inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port));
        
        pthread_t thread;
        pthread_create(&thread, NULL, handle_client, client_sock);
        pthread_detach(thread);
    }
    
    close(server_sock);
    return 0;
}
