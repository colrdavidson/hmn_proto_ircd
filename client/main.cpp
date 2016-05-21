#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <pthread.h>
#include <semaphore.h>

#include "platform.h"

#define url "hmnchat.no-ip.org"
#define port "6667"
#define RX_LEN 512

typedef struct response_config {
	i32 socket_fd;
} response_config;

void *get_response(void *arg) {
	i32 socket_fd = ((response_config *)arg)->socket_fd;
	for (u32 i = 0; i < 10; i++) {
		char recv_msg[RX_LEN + 1];
		int recieve_len;

		if ((recieve_len = recv(socket_fd, recv_msg, RX_LEN, 0)) == -1) {
			printf("recv error!\n");
			return NULL;
		}

		printf("%s\n", recv_msg);
		usleep(10);
	}
	return NULL;
}

int main() {
	struct addrinfo lookup;
	struct addrinfo *result;
	memset(&lookup, 0, sizeof(lookup));
    lookup.ai_family = AF_UNSPEC;
	lookup.ai_socktype = SOCK_STREAM;
	pthread_t read_thread;

	i32 status;
	if ((status = getaddrinfo(url, port, &lookup, &result)) != 0) {
		printf("getaddrinfo: %s\n", gai_strerror(status));
		return 2;
	}

	printf("IP addresses for hmn_proto\n");

	// parse the addrinfo struct and print the ip4 and ip6 address for the url
	char ip[INET6_ADDRSTRLEN];
	for (struct addrinfo *ptr = result; ptr != NULL; ptr = ptr->ai_next) {
		void *addr;
		if (ptr->ai_family == AF_INET) {
			struct sockaddr_in *ipv4 = (struct sockaddr_in *)ptr->ai_addr;
			addr = &(ipv4->sin_addr);
		} else {
			struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)ptr->ai_addr;
			addr = &(ipv6->sin6_addr);
		}

		inet_ntop(ptr->ai_family, addr, ip, sizeof(ip));
		printf("%s\n", ip);
	}

	i32 socket_fd;
	socket_fd = socket(result->ai_family, result->ai_socktype, result->ai_protocol);
    status = connect(socket_fd, result->ai_addr, result->ai_addrlen);

	if (status == -1) {
		printf("connect error!\n");
		return 2;
	}

	response_config response;
	response.socket_fd = socket_fd;

	pthread_create(&read_thread, NULL, get_response, (void *)&response);

	for (u32 i = 0; i < 10; i++) {
		const char *message = "Hello, Server!";
		char send_msg[strlen(message) + sizeof(u32) + 1];
		memset(send_msg, 0, sizeof(send_msg));
		sprintf(send_msg, "%s %u", message, i + 1);

		printf("sent: %s\n", send_msg);
		int send_len;
		if ((send_len = send(socket_fd, send_msg, strlen(message) + sizeof(u32) + 1, 0)) == -1) {
			printf("Send error!\n");
			pthread_exit(NULL);
			return 2;
		}
		sleep(1);
	}

	pthread_join(read_thread,  NULL);
	close(socket_fd);
	return 0;
}
