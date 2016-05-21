#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>

#include "platform.h"

#define url "http://hmnchat.no-ip.org"
#define port "6667"
#define RX_LEN 512
#define TX_LEN 512

int main() {
	struct addrinfo lookup;
	struct addrinfo *result;
	memset(&lookup, 0, sizeof(lookup));
    lookup.ai_family = AF_UNSPEC;
	lookup.ai_socktype = SOCK_STREAM;

	i32 status;
	if ((status = getaddrinfo(url, port, &lookup, &result)) != 0) {
		printf("getaddrinfo: %s\n", gai_strerror(status));
		return 2;
	}

	printf("IP addresses for hmn_proto\n");

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

	char send_msg[TX_LEN];
	sprintf(send_msg, "Hello, Server!\n");

	int send_len;
	if ((send_len = send(socket_fd, send_msg, strlen(send_msg), 0)) == -1) {
		printf("Send error!\n");
		return 2;
	}
	printf("%d %lu\n", send_len, strlen(send_msg));

	char recv_msg[RX_LEN + 1];
	int RCVLength;
	if ((RCVLength = recv(socket_fd, recv_msg, RX_LEN, 0)) == -1) {
		printf("RCV error!\n");
		return 2;
	}

	printf("message: %s\n", recv_msg);
	close(socket_fd);
	return 0;
}
