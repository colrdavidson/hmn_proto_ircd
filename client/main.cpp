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
#define MAX_MSG_LEN 256

typedef struct response_config {
	i32 socket_fd;
} response_config;

void *get_response(void *arg) {
	i32 socket_fd = ((response_config *)arg)->socket_fd;
	while (true) {
		char recv_msg[RX_LEN + 1];

		int recieve_len = recv(socket_fd, recv_msg, RX_LEN, 0);
		if (recieve_len == -1) {
			printf("recv error!\n");
			return NULL;
		}

		printf("%s", recv_msg);
		usleep(10);
	}
	return NULL;
}

bool send_message(i32 socket_fd, char *message) {
	char send_msg[16 + strlen(message) + 1];
	memset(send_msg, 0, sizeof(send_msg));
	char client_id[5] = "0000";
	char room_id[9] = "00000000";

	//set up short message
	message[0] = 0x50;
	message[1] = 0xFF;

	//4b-client message id
	sprintf(send_msg + 2, "%s", client_id);
	message[6] = 0xFF;

	//8b-room id
	sprintf(send_msg + 7, "%s", room_id);
	message[16] = 0xFF;
	sprintf(send_msg + 16, "%s", message);

	printf("sent: %s", send_msg);

	int send_len = send(socket_fd, send_msg, strlen(send_msg), 0);
	if (send_len == -1) {
		printf("Send error!\n");
		return false;
	}
	return true;
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

	bool running = true;
	char message[MAX_MSG_LEN];
	memset(&message, 0, sizeof(message));

	fgets(message, MAX_MSG_LEN, stdin);
	while (running) {
		running = send_message(socket_fd, message);
		fgets(message, MAX_MSG_LEN, stdin);
	}

	pthread_exit(NULL);
	close(socket_fd);
	return 0;
}
