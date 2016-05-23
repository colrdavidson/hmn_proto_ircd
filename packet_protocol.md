```
LINK: http://collabedit.com/x84fs

#Packet Protocol

Single byte packet ID [1-255]
Always first byte.

USERNAME needs to be sanitized to standard viewable ASCII typeset
All packets must end with [00] 

0. used to as an end of packet marker [00]

!START: ON TCP SOCKET CONNECT SERVER QUERIES WITH

S1. request for username/password
packet format: [01][FF]UP[00]
        bytes: (01 FF 55 80 00)

EXPECTS

// --------------------------------------------------
// existing user login

U2. username/password and client endianess response
        packet format: [02][FF][USERNAME][FF][BASE64ENCODED PASSWORD][FF][E 01|02][00]
                bytes: (02 FF [...] FF [...] FF 42|4C 00)
                notes: E = endianess field
                       01 = little|02 = big

    REPLIES

    S3. valid, invalid or missing username/password/endianess
            packet format: [03][FF][U 01|02|03][P 01|02|03][E 01|02|03][00]
                    bytes: (03 FF 01|02|03 01|02|03 01|02|03 00)
                    notes: U = username field
                           01 = missing|02 = invalid|03 = okay
                           
                           P = password field (base64 ecoding required)
                           01 = missing|02 = invalid|03 = okay|04 = bad base 64 encode
                           
                           E = endianess field
                           01 = missing|02 = invalid|03 = okay

                 examples: (03 FF 03 03 03 00) = authenticated
                           (03 FF 03 02 01 00) = username good, password invalid, endianess is missing
    OR

    S4. bad username/password/endianess packet format
            packet format: [04][FF]BAD[00]
                    bytes: (04 FF 42 41 44 00)
                    
    OR
    
    S5. server does not allow multi-user endpoint logins
            packet format: [05][FF]BAD[00]
                    bytes: (05 FF 42 41 44 00)
                    
    END REPLIES

OR

// --------------------------------------------------
// new user registration

U6. register new user
packet format: [06][FF][USERNAME][FF][BASE64ENCODED PASSWORD][FF][EMAIL][00]
        bytes: (06 FF [...] FF [...] FF [...] 00)
        notes: EMAIL = required for password reset...

    REPLIES
        
    S7. valid, invalid or missing user registration 
            packet format: [07][FF][U 01|02|03|04][P 01|02|03|04][FF][E 01|02|03][00]
                    bytes: (07 FF 01|02|03|04 01|02|03 00)
                    notes: U = username field
                           01 = missing|02 = invalid|03 = okay|04 = taken

                           P = password field (base64 ecoding required)
                           01 = missing|02 = invalid|03 = okay|04 = bad base 64 encode
                           
                           E = email field
                           01 = missing|02 = invalid|03 = okay
                           
                 examples: (03 FF 03 03 03 00) = user successfully registered [counted as authenticated by the server automatically]
                           (03 FF 04 02 03 00) = username already in use, password invalid, email valid
                           
              server duty: on valid, server needs to send an email containing a validation to the supplied mail account

    OR
    
    S8. bad user registration packet format
            packet format: [08][FF]BAD[00]
                    bytes: (08 FF 42 41 44 00)
    
OR

// --------------------------------------------------
// ivalid response to the initial TCP connect

S9. bad response to original TCP connect query
        packet format: [09][FF]BAD[00]
                bytes: (09 FF 42 41 44 00)

!END: ON TCP SOCKET CONNECT SERVER QUERIES WITH

//----------------------------------------------------
//PACKET 10-79 are reserved...
//to sort out the rest of this packet mess
//----------------------------------------------------
//
//need validation for email
//social/media links optional 
//GENDER = [01 = Male|02 = Female|03 = Trans|04 = Other|05 = Mayo]
//DOB = date of birth [MM/DD/YY], NAME [optional but [FF] delimiters must still mark the empty fields]
//[FF][EMAIL][FF][GENDER][FF][DOB][FF][NAME]

// [user] update user information
//packet format: [03][FF][BASE64ENCODED PASSWORD[FF][EMAIL ADDRESS][FF]M|F|T|O[FF][DOB MM/DD/YY][FF][NAME][00]
//        bytes: (03 FF [...] [FF] [...] [FF] 4D|46|54|4F [...] FF [...] 00)
//        NOTES: EMAIL, GENDER, DOB, NAME ARE OPTIONAL...


// [user] profile privacy settings
//packet format: [05][FF]D|H[FF]D|H[FF]D|H[FF]D|H[00]
//        bytes: (05 FF 44|48 FF 44|48 FF 44|48 FF 44|48 00)
//        NOTES: D = DISPLAY|H = HIDE - EMAIL, GENDER, DOB, NAME
// [user] delete account
// [server] account deleted
// [user] recover account
// [server] account recovered
//  [user] send user avatar.png head
//packet format: [05][FF][4 bytes][FF][BASE64ENCODED 4000 BYTE MAX][00]
//        bytes: (05 [FF] [...] FF [...] 00)
//        NOTES: 4 byte encoded UINT32 marks the number of remaning packets [1..X]
//.  [user] send user avatar.png next
//packet format: [06][FF][XX][FF][BASE64ENCODED 4000 BYTE MAX][00]
//        bytes: (06 FF XX FF [...] 00)
//       NOTES: XX is the packet #
//  [server] send user avatar.png head
//packet format: [07][FF][4 bytes][FF][BASE64ENCODED 4000 BYTE MAX][00]
//        bytes: (07 [FF] [...] FF [...] 00)
//       NOTES: 4 byte encoded UINT32 marks the number of remaning packets [1..X]
//  [server] send user avatar next
//packet format: [08][FF][XX][FF][BASE64ENCODED 4000 BYTE MAX][00]
//        bytes: (08 FF XX FF [...] 00)
//        NOTES: XX is the packet #
//  [user] set social media links
// [user] update social media links
// [user] fetch user details packet A - email, base stuff... 
// [user] fetch user details packet B - social media stuff..
// [user] fetch user details packer C - other stalkery stuff...
//  [user] set user chat alias
//  [server] user alias update
//  [user] mute/unmute user
//packet format: [09][FF][01][FF][USERNAME][00]
//        bytes: (09 FF [..] 00)
// [user] unmute user
//packet format: [0A][FF][USERNAME][00]
//      bytes: (0A FF [..] 00)
// [user] friend user
//packet format: [0B][FF][USERNAME][00]
//        bytes: (0B FF [...] 00)
//
//33. [user] unfriend user
//packet format: [0C][FF][USERNAME][00]
//        bytes: (0C FF [...] 00)
// [user] silence user
//packet format: [0D][FF][USERNAME][FF][REASON][FF][MINUTES][FF][HOURS][FF][DAYS][FF][MONTHS][FF][YEARS][00]
//        bytes: (0D FF [...] FF [...] FF [0..59] FF [0..23] FF [0..11] FF [0..255] 00)
//        NOTES: if no time spans are given a default of 15 minutes is assumed.      
// [server] not authorized to silence users
//packet format: [0E][FF]SU[00]
//        bytes: (0E FF 53 55 00)        
// [user] ban user
//packet format: [0F][FF][USERNAME][FF][REASON][FF][MINUTES][FF][HOURS][FF][DAYS][FF][MONTHS][FF][YEARS][00]
//       bytes: (0F FF [...] FF [...] FF [0..59] FF [0..23] FF [0..11] FF [0..255] 00)
//     NOTES: if no time spans are given a default of 3 hours is assumed.        
// [server] not authorized to ban users
//packet format: [10][FF]BU[00]
//        bytes: (10 FF 42 55 00)
// [user] unban user
//packet format: [11][FF][USERNAME][00]
//        bytes: (11 FF [...] 00)
// [server] not authorized to uban users
//packet format: [12][FF]UU[00]
//        bytes: (12 FF 55 55 00)
// user has gone offline
// user has come online

!START: MESSAGING PACKETS

16-BYTE UNIQUE ID
   - 1st 8-bytes of an incremental counter controlled by the server
   - 2nd 8-bytes follow http://www.w3schools.com/jsref/jsref_gettime.asp

8-BYTE UNIQUE ROOM ID
   - ROOM ID (00 00 00 00 00 00 00 00) is always used for global message broadcast
   - incremental room counter to prevent collisions on logs controlled by the server

4-BYTE CLIENT MESSAGE ID
   - Session only.
   - Can reset on reconnect.
   - Must be unique so only one instance of it appears per session.
        - possibly uint32 counter advised

// --------------------------------------------------
// short message from user

U80. short chat message
         packet format: [50][FF][4-BYTE CLIENT MESSAGE ID][FF][8-BYTE UNIQUE ROOM ID][FF][BASE64ENCODED 4000 BYTE MAX][00]
                 bytes: (50 FF [...] FF [...] FF [...] 00)

REPLIES

S81. valid, invalid or missing short chat message packet data
         packet format: [51][FF][4-BYTE CLIENT MESSAGE ID][FF][RID 01|02|03|04][M 01|02|03|04|05][00]
                 bytes: (51 FF [...] FF 01|02|03|04 01|02|03|04|05 00)
                 notes: RID = uniqie room id field
                        01 = missing|02 = invalid|03 = okay|04 = not authrized
                        
                        M = messge body field
                        01 = missing|02 = invalid|03 = okay|04 = bad base 64 encode|05 = empty

OR

S82. bad short chat message format
         packet format: [52][FF][4-BYTE CLIENT MESSAGE ID]BAD[00]
                 bytes: (52 FF 42 41 44 00)

// --------------------------------------------------
// short message from server
    
S83. short chat message
         packet format: [53][FF][16-BYTE UNIQUE ID][FF][8-BYTE UNIQUE ROOM ID][FF][BASE64ENCODED 4000 BYTE MAX][00]
                 bytes: (53 FF [...] FF [...] FF [...] 00)

// --------------------------------------------------
// long message from user

U84. long chat message head
packet format: [54][FF][TP 4 bytes][FF][4-BYTE CLIENT MESSAGE ID][FF][8-byte UNIQUE ROOM ID][FF][BASE64ENCODED 4000 BYTE MAX][00]
        bytes: (54 [FF] [...] FF [...] FF [...] FF [...] 00)
        NOTES: TP [UINT32] = number of remaning packets [1..X]

U85. long chat message next
packet format: [55][FF][LCPID 4 bytes][FF][HEAD 4-BYTE CLIENT MESSAGE ID][03][BASE64ENCODED 4000 char hard limit][00]
        bytes: (55 FF [...] FF [...] FF [..] 00)
        NOTES: LCPID [UINT32] = packet # within then group of 

REPLIES

S86. resend long chat message next packet

OR

S87. valid, invalid, missing long chat message head packet data

OR

S87. bad long chat message head packet format
         packet format: [57][FF][4-BYTE CLIENT MESSAGE ID][00]
                 bytes: (57 FF [...] 00)

OR

S88. valid, invalid, missing long chat message next packet data

OR

S89. bad long chat message next packet format
         packet format: [59][FF][4-BYTE CLIENT MESSAGE ID][00]
                 bytes: (59 FF [...] 00)



// --------------------------------------------------
// long message from server

U90. long chat message head
packet format: [54][FF][4 bytes][FF][4-BYTE CLIENT MESSAGE ID][FF][8-byte UNIQUE ROOM ID][FF][BASE64ENCODED 4000 BYTE MAX][00]
        bytes: (54 [FF] [...] FF [...] FF [...] FF [...] 00)
        NOTES: 4 byte encoded UINT32 marks the number of remaning packets [1..X]

U91. long chat message next
packet format: [55][FF][XX][FF][HEAD 4-BYTE CLIENT MESSAGE ID][03][BASE64ENCODED 4000 char hard limit][00]
        bytes: (55 FF XX FF [...] FF [..] 00)
        NOTES: XX is the packet #

REPLIES

S92. resend long chat message next packet

OR

S93. valid, invalid, missing long chat message head packet data

OR

S94. bad long chat message head packet format
         packet format: [5E][FF][4-BYTE CLIENT MESSAGE ID]BAD[00]
                 bytes: (5E FF 42 41 44 00)

OR

S95. valid, invalid, missing long chat message next packet data

OR

S96. bad long chat message next packet format
         packet format: [60][FF][4-BYTE CLIENT MESSAGE ID][00]
                 bytes: (60 FF [...] 00)



// --------------------------------------------------
// short message edit







!END: MESSAGING PACKETS


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
```
