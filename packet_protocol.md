```
Packet Protocol

- Single byte packet ID [1-255]
- Always first byte.
- USERNAME needs to be sanitized to standard viewable ASCII typeset
- All packets end with NULL

0. [NULL] - not used... end of packet marker
1. request for username/password
    packet format: 1[03]UP (01 03 85 80 00)
2. username/password response
    packet format: 2[03]U[03][USERNAME][03]P[03][BASE64ENCODED PASSWORD]
3. register new user
    packet format: 3[03]U[03][USERNAME][03]P[03][BASE64ENCODED PASSWORD[03]E[03][EMAIL ADDRESS]
4. short chat message
    packet format: 4[03][17-byte UNIQUE ID][03][8-byte UNIQUE ROOM ID][03][BASE64ENCODED 4000 char hard limit]
5. long chat message head
    packet format: 5[03][17-byte UNIQUE ID][03][8-byte UNIQUE ROOM ID][03][BASE64ENCODED 4000 char hard limit]
6. long chat message next
    packet format: 6[03][17-byte UNIQUE ID][03][BASE64ENCODED 4000 char hard limit]
7. long chat message tail
    packet format: 7[03][17-byte UNIQUE ID][03][BASE64ENCODED 4000 char hard limit]
```
