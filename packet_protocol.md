```
LINK: http://collabedit.com/x84fs

#Packet Protocol

Single byte packet ID [1-255]
Always first byte.

USERNAME needs to be sanitized to standard viewable ASCII typeset
All packets must end with [00] 

R0. reserved - used as end of packet marker [00]

!START: ON TCP SOCKET CONNECT SERVER QUERIES WITH

Enumerator Return Values for Server Responses

01 = empty field
02 = invalid
03 = okay
04 = bad base 64 encode
05 = unchecked
06 = already validated
07 = already in use
08 = not authorized
09 = not in that room
10 = already in that room
11 = empty message
12 = message body too long

S1. send guest/temporary username to client
        packet format: [01][FF][GUEST/TEMPORARY USERNAME][00]
                bytes: (01 FF ... 00)

EXPECTS

// --------------------------------------------------
// existing user login

U2. username/password and client endianess response
        packet format: [02][FF][USERNAME][FF][BASE64ENCODED PASSWORD][FF][E 01|02][00]
                bytes: (02 FF [...] FF [...] FF 42|4C 00)
                notes: E = endianness field
                       possible values [01 = little|02 = big]

    REPLIES

    S3. valid, invalid or missing username/password/endianess
            packet format: [03][FF][U 01|02|03][P 01|02|03][E 01|02|03][00]
                    bytes: (03 FF 01|02|03 01|02|03 01|02|03 00)
                    notes: U = username field
                           possible values [01 = empty field|02 = invalid|03 = okay|06 = already validated]
                           
                           P = password field (base64 ecoding required)
                           possible values [01 = empty field|02 = invalid|03 = okay|05 = unchecked]
                           
                           E = endianness field
                           possible values [01 = empty field|02 = invalid|03 = okay|05 = unchecked]
                           
                 examples: (03 FF 03 03 03 00) = authenticated
                           (03 FF 01 05 03 00) = username empty, password unchecked, endianess is good
                           (03 FF 06 05 05 00) = user already validated, password unchecked, endianess unchecked
    OR

    S4. bad username/password/endianess packet format
            packet format: [04][FF]BAD[00]
                    bytes: (04 FF 42 41 44 00)
                    
    POSSIBLE REPLIES
    
    S5. server does not allow multi-user endpoint logins
            packet format: [05][FF]BAD[00]
                    bytes: (05 FF 42 41 44 00)    

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
                           possible values: [01 = empty field|02 = invalid|03 = okay|07 = already in use]

                           P = password field (base64 ecoding required)
                           possible values: [01 = empty field|02 = invalid|03 = okay|04 = bad base 64 encode|05 = unchecked]
                           
                           E = email field
                           possible values: [01 = empty field|02 = invalid|03 = okay|05 = unchecked]
                           
                 examples: (03 FF 03 03 03 00) = user successfully registered [counted as authenticated by the server automatically]
                           (03 FF 07 05 05 00) = username already in use, password unchecked, email unchecked
                           
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
//PACKETS 10-39 are reserved...
//to sort out the rest of this missing user packets
//----------------------------------------------------

U40. log off server
        packet format [28][FF]BYE[00]
                bytes: (28 FF 42 59 45 00)
                notes: server will close connection cleanly
                       connections should attempt to use this whenever possible
                       
//----------------------------------------------------
//PACKETS 41-79 are reserved...
//to sort out the rest of this missing user packets
//----------------------------------------------------

// NOTES ON IDENTIFIERS USED FOR MESSAGING

16-BYTE UNIQUE ID
   - 1st 8-bytes of an incremental counter controlled by the server
   - 2nd 8-bytes follow http://www.w3schools.com/jsref/jsref_gettime.asp

8-BYTE UNIQUE ROOM ID
   - ROOM ID ("00000000") is always used for global message broadcast
   - ROOM ID ("0000ECHO") is always used for echo packet test
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
         packet format: [50][FF][4-BYTE CLIENT MESSAGE ID][FF][8-BYTE UNIQUE ROOM ID][FF][MESSAGE BASE64ENCODED 4000 BYTE MAX][00]
                 bytes: (50 FF [...] FF [...] FF [...] 00)

    REPLIES

    S81. valid, invalid or missing short chat message packet data
             packet format: [51][FF][4-BYTE CLIENT MESSAGE ID][FF][RID 01|02|03|08|09][M 01|03|04|11|121][00]
                     bytes: (51 FF [...] FF 01|02|03|08|09 01|03|04|11|12 00)
                     notes: RID = unique room id field
                            possible values: [01 = empty field|02 = invalid|03 = okay|08 = not authrized|09 = not in that room]
                        
                            M = messge body field
                            possible values: [01 = empty field|03 = okay|04 = bad base 64 encode|11 = empty message|12 = message body too long]

    OR
    
    S82. bad short chat message format
            packet format: [52][FF]BAD[00]
                    bytes: (52 FF 42 41 44 00)
                    notes: this packet is virtually useless, client won't know what message is attached to.
                           it's just a general... you really messed up sending a packet of this type.
    

// --------------------------------------------------
// short message from server
    
S83. short chat message
         packet format: [53][FF][16-BYTE UNIQUE ID][FF][8-BYTE UNIQUE ROOM ID][FF][USERNAME][FF][ALIAS][FF][MESSAGE BASE64ENCODED 4000 BYTE MAX][00]
                 bytes: (53 FF [...] FF [...] FF [...] FF [...] FF [...] 00)
                 notes: [ALIAS] can be a blank field.
                 
    REPLIES
    
    U84. short chat message received
             packet format: [54][FF][16-BYTE UNIQUE ID][00]
                     bytes: (54 FF [..] 00)
                     
        REPLIES
        
        S85. bad short chat message received reply
                 packet format: [55][FF][16-BYTE UNIQUE ID][00]
                         bytes: (55 FF [...] 00)
                         notes: only used if reply didn't match a valid message on ack.
                                debug packet only.                       
                         
        OR
        
        S86. bad short chat message received reply
                 packet format: [56][FF]BAD[00]
                         bytes: (56 FF 42 41 44 00)
                         notes: this packet is virtually useless, client won't know what message is attached to.
                                it's just a general... you really messed up sending a packet of this type.

!END: SHORT MESSAGING PACKETS

!START: LONG MESSAGING PACKETS

// --------------------------------------------------
// long message head from user

U87. long chat message head
         packet format: [57][FF][TP 4 bytes][FF][4-BYTE CLIENT MESSAGE ID][FF][8-byte UNIQUE ROOM ID][FF][BASE64ENCODED 4000 BYTE MAX][00]
                 bytes: (57 [FF] [...] FF [...] FF [...] FF [...] 00)
                 notes: TP [UINT32] = number of remaining packets [1..X]

    REPLIES

    S88. valid, invalid, missing long chat message head packet data
             packet format: [58][FF][4-BYTE CLIENT MESSAGE ID][FF][TP 01|02|03][RID 01|02|03|04][M 01|02|03|04|05][00]
                     bytes: (58 FF [...] FF 01|02|03 01|02|03|04 01|02|03|04|05 00)
                     notes: TP = number of remaning packets field
                            01 = missing|02 = invalid|03 = okay
                            
                            RID = uniqie room id field
                            01 = missing|02 = invalid|03 = okay|04 = not authrized
                        
                            M = messge body field
                            01 = missing|02 = invalid|03 = okay|04 = bad base 64 encode|05 = empty                            

    OR
    
    S89. bad long chat message head packet format
            packet format: [59][FF]BAD[00]
                    bytes: (59 FF 42 41 44 00)
                    notes: this packet is virtually useless, client won't know what message is attached to.
                           it's just a general... you really messed up sending a packet of this type.



    POSSIBLE REPLIES
    
    S90. resend long chat message head packet
             packet format: [5A][FF][4-BYTE CLIENT MESSAGE ID][00]
                     bytes: (5A FF [...] 00)


// --------------------------------------------------
// long message next from user

U91. long chat message next
         packet format: [5B][FF][PN 4 bytes][FF][HEAD 4-BYTE CLIENT MESSAGE ID][FF][MESSAGE BASE64ENCODED 4000 BYTE MAX][00]
                 bytes: (5B FF [...] FF [...] FF [..] 00)
                 notes: PN [UINT32] = packet # 

    REPLIES

    S92. valid, invalid, missing long chat message next packet data
             packet format: [5C][FF][HEAD 4-BYTE CLIENT MESSAGE ID][FF][PN 01|02|03][RID 01|02|03|04][M 01|02|03|04|05][00]
                     bytes: (5C FF [...] FF 01|02|03 01|02|03|04 01|02|03|04|05 00)
                     notes: PN = packet #
                            01 = missing|02 = invalid|03 = okay
                            
                            RID = uniqie room id field
                            01 = missing|02 = invalid|03 = okay|04 = not authrized
                        
                            M = messge body field
                            01 = missing|02 = invalid|03 = okay|04 = bad base 64 encode|05 = empty                            
     
    OR

    S93. bad long chat message next packet format
            packet format: [5D][FF]BAD[00]
                    bytes: (5D FF 42 41 44 00)
                    notes: this packet is virtually useless, client won't know what message is attached to.
                           it's just a general... you really messed up sending a packet of this type.
     
    POSSIBLE REPLIES
     
    S94. resend long chat message next packet
             packet format: [5E][FF][PN 4 bytes][FF][4-BYTE CLIENT MESSAGE ID][00]
                     bytes: (5E FF [...] FF [...] 00)
                     notes: PN [UINT32] = packet # 

// --------------------------------------------------
// long message next from server

U95. long chat message head
         packet format: [5F][FF][TP 4-BYTE][FF][16-BYTE UNIQUE ID][FF][8-BYTE UNIQUE ROOM ID][FF][MESSAGE BASE64ENCODED 4000 BYTE MAX][00]
                 bytes: (5F [FF] [...] FF [...] FF [...] FF [...] 00)
                 notes: TP [UINT32] = number of remaining packets [1..X]

    REPLIES
    
    U96. long chat message head received
             packet format: [60][FF][16-BYTE UNIQUE ID][00]
                     bytes: (60 FF [...] 00)
                     
        REPLIES
        
        S97. bad long chat message received reply
                 packet format: [61][FF][FIRST 8-BYTES OF 16-BYTE UNIQUE ID][00]
                         bytes: (61 FF 42 41 44 00)
                         notes: only used if reply didn't match a valid message on ack.
                                debug packet only.
                                
        OR
        
        S98. bad long chat message recieved reply
            packet format: [62][FF]BAD[00]
                    bytes: (62 FF 42 41 44 00)
                    notes: this packet is virtually useless, client won't know what message is attached to.
                           it's just a general... you really messed up sending a packet of this type.


    POSSIBLE REPLIES

    U99. resend long chat message next packet
             packet format: [63][FF][PN 4 bytes][FF][FIRST 8-BYTES OF 16-BYTE UNIQUE ID][00]
                     bytes: (63 FF [...] FF [...] 00)
                     notes: PN [UINT32] = packet # 

        REPLIES
        
        S100. valid, invalid, missing resend long chat message next packet data
                 packet format: [64][FF][FIRST 8-BYTES OF 16-BYTE UNIQUE ID][FF][PN 01|02|03][RID 01|02|03|04][M 01|02|03|04|05][A 0|1][00]
                         bytes: (64 FF [...] FF 01|02|03 01|02|03|04 01|02|03|04|05 00)
                         notes: PN = packet #
                                01 = missing|02 = invalid|03 = okay
                            
                                RID = unique room id field
                                01 = missing|02 = invalid|03 = okay|04 = not authrized
                        
                                M = messge body field
                                01 = missing|02 = invalid|03 = okay|04 = bad base 64 encode|05 = empty
                                
                                A = some other reason the request might not authorized
                                00 = not authorized|01 = okay

        OR

        S101. bad resend long chat message next packet format
                 packet format: [65][FF][PN 4 bytes][FF][16-BYTE UNIQUE ID][00]
                         bytes: (65 FF [...] FF [...] 00)
                         notes: only used if reply didn't match a valid message on ack.
                                debug packet only. 
        
        OR
        
        S102. bad resend long chat message next packet format
                 packet format: [66][FF]BAD[00]
                         bytes: (66 FF 42 41 44 00)
                         notes: this packet is virtually useless, client won't know what message is attached to.
                                it's just a general... you really messed up sending a packet of this type.

!END: LONG MESSAGING PACKETS


//----------------------------------------------------
//PACKETS 103-159 are reserved...
//to sort out the rest of this missing messaging packets
//----------------------------------------------------

U160. join room
        packet format: [A0][FF][8-BYTE UNIQUE ROOM ID][FF][BASE64ENCODED PASSWORD][00]
                bytes: (A0 FF [..] FF [..] 00)
                notes: when joining a room you can leave the password blank
                       this field is ownly needed for rooms that are password protected
        
        REPLIES:
                       
        S161. valid, invalid join room request
                packet format: [A1][FF][8-BYTE UNIQUE ROOM ID][FF][RID 01|02|03|08|09|10][00]
                        bytes: (A1 FF [...] FF 01|02|03|08|09|10 00)
                        notes: RID = unique room id field
                               possible values: [01 = empty field|02 = invalid|03 = okay|08 = not authrized|09 = not in that room|10 = already in that room]

        AND [IF JOIN VALID]
                
        S162. user joined room
                packet format: [A2][FF][8-BYTE UNIQUE ROOM ID][FF][USERNAME][FF][ALIAS][00]
                        bytes: (A2 FF [...] FF [...] FF [...] 00)
                        
        
U163. part room
        packet format: [A3][FF][8-BYTE UNIQUE ROOM ID][FF][PART MESSAGE][00]
                bytes: (A3 FF [..] 00)
        
        REPLIES:
                       
        S164. valid, invalid part room request
                packet format: [A4][FF][8-BYTE UNIQUE ROOM ID][FF][RID 01|02|03|09][00]
                        bytes: (A4 FF [...] FF 01|02|03|09 00)
                        notes: RID = unique room id field
                               possible values: [01 = empty field|02 = invalid|03 = okay|09 = not in that room]

        AND [IF PART VALID]
                
        S165. user parted room
                packet format: [A5][FF][8-BYTE UNIQUE ROOM ID][FF][USERNAME][FF][ALIAS][00]
                        bytes: (A2 FF [...] FF [...] FF [...] 00)

U166. change user alias
        packet format: [A6][FF][NEW ALIAS][00]
                bytes: (A6 FF [...] 00)
                notes: this is handled per socket, not by user as multi-endpoint can cause confusion
                       so each socket endpoint within a user can have seperate aliases.
                       this won't matter if single endpoint is configured on the server.
                       
        REPLIES:
        
        S167. valid, invalid request to change user alias
                packet format: [A7][FF][ALIAS 01|02|03|07][00]
                        bytes: (A7 FF 01|02|03|07 00)
                        notes: ALIAS = return code associated with the request to change user alias
                               possible values: [01 = empty field|02 = invalid|03 = okay|07 = already in use]
                               
        AND [IF CHANGE ALIAS VALID]
        
        S168. update user alias
                packet format: [A8][FF][USERNAME][FF][OLD ALIAS][FF][NEW ALIAS][00]
                        bytes: (A8 FF [...] FF [...] FF [...] 00)


U169. invite user to room
        packet format: [A9][FF][8-BYTE UNIQUE ROOM ID][FF][USERNAME][FF][ALIAS][00]
                bytes: (A9 FF [...] FF [...] FF [...] 00)
                notes: if alias is left blank then all endpoints associated with username should be sent the invite
                       or if alias is specififed, o


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

22. [server] room created
packet format: [16][FF][8-byte UNIQUE ROOM ID][00]
        bytes: (16 FF [...] 00)
        NOTES: user should be informed they need to configure the room before others can join it.


24. [user] configure room settings

25. [server] not authorized to change room settings

24. [user] leave a room
packet format : [15][FF][8-byte UNIQUE ROOM ID]


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
