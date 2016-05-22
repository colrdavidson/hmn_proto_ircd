#Packet Protocol

Single byte packet ID [1-255]
Always first byte.

USERNAME needs to be sanitized to standard viewable ASCII typeset
All packets must end with [00] 

0. used to as an end of packet marker [00]

1. [server] request for username/password
packet format: [01][FF]UP[00]
        bytes: (01 FF 55 80 00)

2. [user] username/password and endianess response
packet format: [02][FF][USERNAME][FF][BASE64ENCODED PASSWORD][FF]B|L[00]
        bytes: (02 FF [...] FF [...] FF 42|4C 00)
        NOTES: 42|4C it will be either/or to mark the endianess as Big or Little that the client supports

3. [server] missing username
packet format: [03][FF]MU[00]
        bytes: (03 FF 4D 55 45 00)

4. [server] missing password
packet format: [04][FF]MP[00]
        bytes: (04 FF 4D 4E 45 00)

5. [server] missing endianness
packet format: [5][FF]ME[00]
        bytes: (05 FF 4D 45 00)

6. [user] register new user
packet format: [03][FF][USERNAME][FF][BASE64ENCODED PASSWORD[FF][EMAIL ADDRESS][FF]M|F|T|O[FF][DOB][FF][NAME][00]
        bytes: (03 FF [...] [FF] [...] [FF] [...] [FF] 4D|46|54|4F [...] FF [...] 00)
        NOTES: EMAIL, GENDER, DOB [MM/DD/YY], NAME ARE OPTIONAL...

7. [server] username not available
packet format: [04][FF]UNA[00]
        bytes: (04 FF 55 4E 45 00)

8. [user] profile privacy settings
packet format: [05][FF]D|H[FF]D|H[FF]D|H[FF]D|H[00]
        bytes: (05 FF 44|48 FF 44|48 FF 44|48 FF 44|48 00)
        NOTES: D = DISPLAY|H = HIDE - EMAIL, GENDER, DOB, NAME

9. [user] update user information
packet format: [03][FF][BASE64ENCODED PASSWORD[FF][EMAIL ADDRESS][FF]M|F|T|O[FF][DOB MM/DD/YY][FF][NAME][00]
        bytes: (03 FF [...] [FF] [...] [FF] 4D|46|54|4F [...] FF [...] 00)
        NOTES: EMAIL, GENDER, DOB, NAME ARE OPTIONAL...

10. [user] delete account
11. [server] account deleted

12. [user] recover account
13. [server] account recovered

14.  [user] send user avatar.png head
packet format: [05][FF][4 bytes][FF][BASE64ENCODED 4000 BYTE MAX][00]
        bytes: (05 [FF] [...] FF [...] 00)
        NOTES: 4 byte encoded UINT32 marks the number of remaning packets [1..X]

15.  [user] send user avatar.png next
packet format: [06][FF][XX][FF][BASE64ENCODED 4000 BYTE MAX][00]
        bytes: (06 FF XX FF [...] 00)
        NOTES: XX is the packet #

16.  [server] send user avatar.png head
packet format: [07][FF][4 bytes][FF][BASE64ENCODED 4000 BYTE MAX][00]
        bytes: (07 [FF] [...] FF [...] 00)
        NOTES: 4 byte encoded UINT32 marks the number of remaning packets [1..X]

17.  [server] send user avatar next
packet format: [08][FF][XX][FF][BASE64ENCODED 4000 BYTE MAX][00]
        bytes: (08 FF XX FF [...] 00)
        NOTES: XX is the packet #

18.  [user] set social media links
19. [user] update social media links
20. [user] fetch user details packet A - email, base stuff... 
21. [user] fetch user details packet B - social media stuff..
22. [user] fetch user details packer C - other stalkery stuff...
23.  [user] set user chat alias
24.  [server] user alias update

25.  reserved for other user packets
26.  reserved for other user packets
27.  reserved for other user packets
28.  reserved for other user packets
29.  reserved for other user packets

30.  [user] mute user
packet format: [09][FF][USERNAME][00]
        bytes: (09 FF [..] 00)

31. [user] unmute user
packet format: [0A][FF][USERNAME][00]
        bytes: (0A FF [..] 00)

32. [user] friend user
packet format: [0B][FF][USERNAME][00]
        bytes: (0B FF [...] 00)

33. [user] unfriend user
packet format: [0C][FF][USERNAME][00]
        bytes: (0C FF [...] 00)

34. [user] silence user
packet format: [0D][FF][USERNAME][FF][REASON][FF][MINUTES][FF][HOURS][FF][DAYS][FF][MONTHS][FF][YEARS][00]
        bytes: (0D FF [...] FF [...] FF [0..59] FF [0..23] FF [0..11] FF [0..255] 00)
        NOTES: if no time spans are given a default of 15 minutes is assumed.
        
35. [server] not authorized to silence users
packet format: [0E][FF]SU[00]
        bytes: (0E FF 53 55 00)
        
36. [user] ban user
packet format: [0F][FF][USERNAME][FF][REASON][FF][MINUTES][FF][HOURS][FF][DAYS][FF][MONTHS][FF][YEARS][00]
        bytes: (0F FF [...] FF [...] FF [0..59] FF [0..23] FF [0..11] FF [0..255] 00)
        NOTES: if no time spans are given a default of 3 hours is assumed.
        
37. [server] not authorized to ban users
packet format: [10][FF]BU[00]
        bytes: (10 FF 42 55 00)

38. [user] unban user
packet format: [11][FF][USERNAME][00]
        bytes: (11 FF [...] 00)

39. [server] not authorized to uban users
packet format: [12][FF]UU[00]
        bytes: (12 FF 55 55 00)

40.  reserved for other user packets
41.  reserved for other user packets
42.  reserved for other user packets
43.  reserved for other user packets
44.  reserved for other user packets
45.  reserved for other user packets
46.  reserved for other user packets
47.  reserved for other user packets
48.  reserved for other user packets
49.  reserved for other user packets
      
50. [server] short chat message
packet format: [05][FF][16-byte UNIQUE ID][FF][8-byte UNIQUE ROOM ID][FF][BASE64ENCODED 4000 BYTE MAX][00]
        bytes: (05 FF [...] FF [...] FF [...] 00)

51. [server] long chat message head
packet format: [06][FF][4 bytes][FF][16-byte UNIQUE ID][FF][8-byte UNIQUE ROOM ID][FF][BASE64ENCODED 4000 BYTE MAX][00]
        bytes: (06 [FF] [...] FF [...] FF [...] FF [...] 00)
        NOTES: 4 byte encoded UINT32 marks the number of remaning packets [1..X]

52. [server] long chat message next
packet format: [07][FF][XX][FF][HEAD pkt 6 16-byte UNIQUE ID][03][BASE64ENCODED 4000 char hard limit][00]
        bytes: (07 FF XX FF [...] FF [..] 00)
        NOTES: XX is the packet #

53. [user] resend long chat packet request
packet format: [08][FF][4 bytes][00]
        bytes: (08 FF [...] 00)
        NOTES: 42|4C it will be either/or to mark the endianess of the next 4 byte encoded UINT32
               this is the number of the packet being requested for resend

54. [server] bad resend long chat packet request
packet format: [09][FF]BR[00]
        bytes: (09 FF 42 52 00)

55. [user] move message from room to room
packet format: [0A][FF][8-byte UNIQUE ROOM ID][FF][16-byte UNIQUE ID][00]
        bytes: (0A FF [...] [FF] [...] 00)

56. held for other message features
57. held for other message features
58. held for other message features
59. held for other message features

20. [user] create room
packet format: [14][FF]CR[NULL]
        bytes: (14 FF 

21. [server] not authorized to create a room
packet format : [15][FF][8-byte UNIQUE ROOM ID][FF][PASSWORD][NULL]


22. [server] room created
packet format: [16][FF][8-byte UNIQUE ROOM ID][00]
        bytes: (16 FF [...] 00)
        NOTES: user should be informed they need to configure the room before others can join it.



22. [user] join a room
packet format : [16][FF][8-byte UNIQUE ROOM ID][FF][PASSWORD][NULL]

23. [server] not authorized to join that room

24. [server] user joined a room
packet format : 

24. [user] configure room settings

25. [server] not authorized to change room settings

24. [user] leave a room
packet format : [15][FF][8-byte UNIQUE ROOM ID]



10. invite a user to a room
packet format: 9[03][8-byte UNIQUE ROOM ID][03]U[03][INVITING USERNAME][NULL]

11. create a room

251. [server] packet not supported
packet format: [FB][FF]PNS[00]
        bytes: (FB FF 50 4E 53 00)

252. [user] request list of server supported packets
packet format: [FC][FF]SP[00]
        bytes: (FC FF 53 50 00)

253. [server] servers supports these packets
packet format: [FD][FF][XX][...][00]
       bytes: (FE FF XX [...] 00)
       NOTES: XX in this case represents a packet the server supports.
              [...] alots that they should follow [FF][XX] for other packets that are supported

254. [user] client supports these packets
packet format: [FE][FF][XX][...][00]
       bytes: (FE FF XX [...] 00)
       NOTES: XX in this case represents a packet the client supports.
              [...] alots that they should follow [FF][XX] for other packets that are supported


255. used as the delimiter for packet fields
