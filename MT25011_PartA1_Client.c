/*
 * MT25011 - Replace XXX with your roll number
 * PA02 - Part A1: Two-Copy Implementation (Client)
 * Uses recv() socket primitive (baseline with two copies)
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
#include <sys/time.h>
#include <errno.h>

#define DURATION_SECONDS 30

// Global parameters
char *server_ip = NULL;
int server_port = 0;
int message_size = 4096;
volatile int keep_running = 1;

// Statistics structure
typedef struct {
    unsigned long long bytes_received;
    unsigned long long messages_received;
    double start_time;
    double end_time;
} ThreadStats;

// Get current time in seconds
double get_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec / 1000000.0;
}

// Client thread function
void* client_thread(void *arg) {
    ThreadStats *stats = (ThreadStats*)malloc(sizeof(ThreadStats));
    stats->bytes_received = 0;
    stats->messages_received = 0;
    
    // Connect to server
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        perror("socket");
        return stats;
    }
    
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(server_port);
    inet_pton(AF_INET, server_ip, &server_addr.sin_addr);
    
    if (connect(sock, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("connect");
        close(sock);
        return stats;
    }
    
    // Allocate receive buffer
    char *buffer = (char*)malloc(message_size);
    if (!buffer) {
        close(sock);
        return stats;
    }
    
    stats->start_time = get_time();
    
    // Receive messages using recv() - TWO COPY PATH
    // Copy 1: NIC to kernel socket buffer
    // Copy 2: Kernel socket buffer to user space buffer
    while (keep_running) {
        ssize_t received = recv(sock, buffer, message_size, 0);
        if (received < 0) {
            if (errno == EINTR) continue;
            break;
        }
        if (received == 0) break;
        
        stats->bytes_received += received;
        if (received == message_size) {
            stats->messages_received++;
        }
    }
    
    stats->end_time = get_time();
    
    free(buffer);
    close(sock);
    return stats;
}

int main(int argc, char *argv[]) {
    if (argc != 5) {
        fprintf(stderr, "Usage: %s <server_ip> <port> <message_size> <num_threads>\n", argv[0]);
        exit(EXIT_FAILURE);
    }
    
    server_ip = argv[1];
    server_port = atoi(argv[2]);
    message_size = atoi(argv[3]);
    int num_threads = atoi(argv[4]);
    
    printf("[Client A1] Connecting to %s:%d\n", server_ip, server_port);
    printf("[Client A1] Message size: %d bytes\n", message_size);
    printf("[Client A1] Number of threads: %d\n", num_threads);
    printf("[Client A1] Duration: %d seconds\n", DURATION_SECONDS);
    
    pthread_t *threads = (pthread_t*)malloc(sizeof(pthread_t) * num_threads);
    
    // Start all client threads
    for (int i = 0; i < num_threads; i++) {
        pthread_create(&threads[i], NULL, client_thread, NULL);
    }
    
    // Run for specified duration
    sleep(DURATION_SECONDS);
    keep_running = 0;
    
    // Wait for all threads and collect statistics
    unsigned long long total_bytes = 0;
    unsigned long long total_messages = 0;
    double min_start = 0, max_end = 0;
    
    for (int i = 0; i < num_threads; i++) {
        ThreadStats *stats;
        pthread_join(threads[i], (void**)&stats);
        
        total_bytes += stats->bytes_received;
        total_messages += stats->messages_received;
        
        if (i == 0 || stats->start_time < min_start) min_start = stats->start_time;
        if (stats->end_time > max_end) max_end = stats->end_time;
        
        free(stats);
    }
    
    double duration = max_end - min_start;
    double throughput_gbps = (total_bytes * 8.0) / (duration * 1e9);
    double latency_us = (duration * 1e6) / total_messages;
    
    printf("\n[Client A1] Results:\n");
    printf("Total bytes received: %llu\n", total_bytes);
    printf("Total messages: %llu\n", total_messages);
    printf("Duration: %.2f seconds\n", duration);
    printf("Throughput: %.2f Gbps\n", throughput_gbps);
    printf("Average latency: %.2f µs\n", latency_us);
    
    free(threads);
    return 0;
}
