```
LINK: http://collabedit.com/x84fs

#Packet Protocol

Single byte packet ID [1-255]
Always first byte.

USERNAME needs to be sanitized to standard viewable ASCII typeset
All packets must end with [00] 

R0. reserved - used as end of packet marker [00]

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
                notes: server will close the connection

!END: ON TCP SOCKET CONNECT SERVER QUERIES WITH

//----------------------------------------------------
//PACKETS 10-79 are reserved...
//to sort out the rest of this missing user packets
//----------------------------------------------------

// NOTES ON IDENTIFIERS USED FOR MESSAGING

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

!START: SHORT MESSAGING PACKETS

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
             packet format: [52][FF][4-BYTE CLIENT MESSAGE ID][00]
                     bytes: (52 FF [...] 00)
                     
    OR
    
    S83. bad short chat message format
            packet format: [53][FF]BAD[00]
                    bytes: (53 FF 42 41 44 00)
                    notes: this packet is virtually useless, client won't know what message is attached to.
                           it's just a general... you really messed up sending a packet of this type.
    

// --------------------------------------------------
// short message from server
    
S84. short chat message
         packet format: [54][FF][16-BYTE UNIQUE ID][FF][8-BYTE UNIQUE ROOM ID][FF][BASE64ENCODED 4000 BYTE MAX][00]
                 bytes: (54 FF [...] FF [...] FF [...] 00)

    REPLIES
    
    U85. short chat message received
             packet format: [55][FF][FIRST 8-BYTES OF 16-BYTE UNIQUE ID][00]
                     bytes: (55 FF [..] 00)
                     
        REPLIES
        
        S86. bad short chat message received reply
                 packet format: [56][FF][FIRST 8-BYTES OF 16-BYTE UNIQUE ID][00]
                         bytes: (56 FF [...] 00)
                         
                         
        OR
        
        S87. bad short chat message received reply
                 packet format: [57][FF]BAD[00]
                         bytes: (57 FF 42 41 44 00)
                         notes: this packet is virtually useless, client won't know what message is attached to.
                                it's just a general... you really messed up sending a packet of this type.

!END: SHORT MESSAGING PACKETS

!START: LONG MESSAGING PACKETS

// --------------------------------------------------
// long message head from user

U88. long chat message head
         packet format: [58][FF][TP 4 bytes][FF][4-BYTE CLIENT MESSAGE ID][FF][8-byte UNIQUE ROOM ID][FF][BASE64ENCODED 4000 BYTE MAX][00]
                 bytes: (58 [FF] [...] FF [...] FF [...] FF [...] 00)
                 notes: TP [UINT32] = number of remaining packets [1..X]

    REPLIES

    S89. valid, invalid, missing long chat message head packet data
             packet format: [59][FF][4-BYTE CLIENT MESSAGE ID][FF][TP 01|02|03][RID 01|02|03|04][M 01|02|03|04|05][00]
                     bytes: (59 FF [...] FF 01|02|03 01|02|03|04 01|02|03|04|05 00)
                     notes: TP = number of remaning packets field
                            01 = missing|02 = invalid|03 = okay
                            
                            RID = uniqie room id field
                            01 = missing|02 = invalid|03 = okay|04 = not authrized
                        
                            M = messge body field
                            01 = missing|02 = invalid|03 = okay|04 = bad base 64 encode|05 = empty                            

    OR

    S90. bad long chat message head packet format
             packet format: [5A][FF][4-BYTE CLIENT MESSAGE ID][00]
                     bytes: (5A FF [...] 00)

    OR
    
    S91. bad long chat message head packer format
            packet format: [5B][FF]BAD[00]
                    bytes: (5B FF 42 41 44 00)
                    notes: this packet is virtually useless, client won't know what message is attached to.
                           it's just a general... you really messed up sending a packet of this type.



    POSSIBLE REPLIES
    
    S92. resend long chat message head packet
             packet format: [5C][FF][4-BYTE CLIENT MESSAGE ID][00]
                     bytes: (5C FF [...] 00)


// --------------------------------------------------
// long message next from user

U93. long chat message next
         packet format: [5D][FF][PN 4 bytes][FF][HEAD 4-BYTE CLIENT MESSAGE ID][03][BASE64ENCODED 4000 char hard limit][00]
                 bytes: (5D FF [...] FF [...] FF [..] 00)
                 notes: PN [UINT32] = packet # 

    REPLIES

    S94. valid, invalid, missing long chat message next packet data
             packet format: [5E][FF][HEAD 4-BYTE CLIENT MESSAGE ID][FF][PN 01|02|03][RID 01|02|03|04][M 01|02|03|04|05][00]
                     bytes: (5E FF [...] FF 01|02|03 01|02|03|04 01|02|03|04|05 00)
                     notes: PN = packet #
                            01 = missing|02 = invalid|03 = okay
                            
                            RID = uniqie room id field
                            01 = missing|02 = invalid|03 = okay|04 = not authrized
                        
                            M = messge body field
                            01 = missing|02 = invalid|03 = okay|04 = bad base 64 encode|05 = empty                            

    OR

    S95. bad long chat message next packet format
             packet format: [5F][FF][4-BYTE CLIENT MESSAGE ID][00]
                     bytes: (5F FF [...] 00)
     
    OR

    S96. bad long chat message next packer format
            packet format: [60][FF]BAD[00]
                    bytes: (60 FF 42 41 44 00)
                    notes: this packet is virtually useless, client won't know what message is attached to.
                           it's just a general... you really messed up sending a packet of this type.
     
    POSSIBLE REPLIES
     
    S97. resend long chat message next packet
             packet format: [61][FF][PN 4 bytes][FF][4-BYTE CLIENT MESSAGE ID][00]
                     bytes: (61 FF [...] FF [...] 00)
                     notes: PN [UINT32] = packet # 

// --------------------------------------------------
// long message next from server

U98. long chat message head
         packet format: [62][FF][TP 4 bytes][FF][16-BYTE UNIQUE ID][FF][8-byte UNIQUE ROOM ID][FF][BASE64ENCODED 4000 BYTE MAX][00]
                 bytes: (62 [FF] [...] FF [...] FF [...] FF [...] 00)
                 notes: TP [UINT32] = number of remaining packets [1..X]

    REPLIES
    
    U99. long chat message head received
             packet format: [63][FF][FIRST 8-BYTES OF 16-BYTE UNIQUE ID][00]
                     bytes: (63 FF [...] 00)
                     
        REPLIES
        
        S100. bad long chat message received reply
                 packet format: [64][FF][FIRST 8-BYTES OF 16-BYTE UNIQUE ID][00]
                         bytes: (64 FF 42 41 44 00)
                         notes: this is only rebounded if for some reason the UNIQUE ID didn't match a known message
        OR
        
        S101. bad long chat message recieved reply
            packet format: [65][FF]BAD[00]
                    bytes: (65 FF 42 41 44 00)
                    notes: this packet is virtually useless, client won't know what message is attached to.
                           it's just a general... you really messed up sending a packet of this type.


    POSSIBLE REPLIES

    U102. resend long chat message next packet
             packet format: [66][FF][PN 4 bytes][FF][FIRST 8-BYTES OF 16-BYTE UNIQUE ID][00]
                     bytes: (66 FF [...] FF [...] 00)
                     notes: PN [UINT32] = packet # 

        REPLIES
        
        S103. valid, invalid, missing resend long chat message next packet data
                 packet format: [67][FF][FIRST 8-BYTES OF 16-BYTE UNIQUE ID][FF][PN 01|02|03][RID 01|02|03|04][M 01|02|03|04|05][A 0|1][00]
                         bytes: (67 FF [...] FF 01|02|03 01|02|03|04 01|02|03|04|05 00)
                         notes: PN = packet #
                                01 = missing|02 = invalid|03 = okay
                            
                                RID = unique room id field
                                01 = missing|02 = invalid|03 = okay|04 = not authrized
                        
                                M = messge body field
                                01 = missing|02 = invalid|03 = okay|04 = bad base 64 encode|05 = empty
                                
                                A = some other reason the request might not authorized
                                00 = not authorized|01 = okay

        OR

        S104. bad resend long chat message next packet format
                 packet format: [68][FF][PN 4 bytes][FF][FIRST 8-BYTES OF 16-BYTE UNIQUE ID][00]
                         bytes: (68 FF [...] FF [...] 00)
                         notes: this is only rebounded if for some reason the request didn't match a known message
        
        OR
        
        S105. bad resend long chat message next packet format
                 packet format: [69][FF]BAD[00]
                         bytes: (69 FF 42 41 44 00)
                         notes: this packet is virtually useless, client won't know what message is attached to.
                                it's just a general... you really messed up sending a packet of this type.

!END: LONG MESSAGING PACKETS

R255. used as the delimiter for packet fields










//--------------------------------------------------------------
//--------------------------------------------------------------
//--------------------------------------------------------------
// PAST THIS POINT IS ALL NOTES...
// UNFINISHED PACKETS AND THINGS TO BE IMPLEMENTED
//--------------------------------------------------------------
//--------------------------------------------------------------
//--------------------------------------------------------------









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






// --------------------------------------------------
// short message edit







!END: MESSAGING PACKETS




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

S251. packet not supported
         packet format: [FB][FF][PID 1..254][00]
                 bytes: (FB FF [...] 00)
                 notes: PID is the packet ID client tried to either send or query the server for 

U252. request list of server supported packets
         packet format: [FC][FF]RLOSSP[00]
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
```
