```
#Packet Protocol

Single byte packet ID [1-255]
Always first byte.

USERNAME needs to be sanitized to standard viewable ASCII typeset
All packets must end with [00] 

R0. reserved - used as end of packet marker [00]

!START: ON TCP SOCKET CONNECT TO SERVER

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
13 = existing long message pending
14 = bad user
15 = auto-rejected

S1. send guest/temporary username to client
        packet format: [01]
        			   [FF]
        			   [GUEST/TEMPORARY USERNAME]
        			   [00]
        			   
                bytes: (01 FF [..] 00)

EXPECTS

// --------------------------------------------------
// existing user login

U2. username/password and client endianess response
        packet format: [02]
                       [FF]
                       [USERNAME]
                       [FF]
                       [ALIAS]
                       [FF]
                       [BASE64 ENCODED PASSWORD]
                       [FF]
                       [E B|L][00]
                       
                bytes: (02 FF [..] FF [..] FF [..] FF 42|4C 00)
                notes: E = endianness field
                       possible values: L = little
                                        B = big

    REPLIES

    S3. valid, invalid or missing username/password/endianess
            packet format: [03]
                           [FF]
                           [U 01|02|03|06]
                           [A 02|03|05|07]
                           [P 01|02|03|05]
                           [E 01|02|03|05]
                           [FF]
                           [BASE URL TO USER AVATARS]
                           [00]
                           
                    bytes: (03 FF 01|02|03|06 01|02|03|05 01|02|03|05 00)
                    notes: U = username field
                           possible values: 01 = empty field
                                            02 = invalid
                                            03 = okay
                                            06 = already validated
                           
                           A = alias field
                           possible values: 02 = invalid
                                            03 = okay
                                            05 = unchecked
                                            07 = already in use
                           notes: if alias is left blank, alias on first endpoint will be assigned the base username
                                  if left blank on multiple endpoint, server will generate a unique alias for each
                                                      
                           P = password field (base64 ecoding required)
                           possible values: 01 = empty field
                                            02 = invalid
                                            03 = okay
                                            05 = unchecked
                           
                           E = endianness field
                           possible values: 01 = empty field
                                            02 = invalid
                                            03 = okay
                                            05 = unchecked
                           
                           [BASE URL TO USER AVATARS] = only supplied on successful validaton
                           
                 examples: (03 FF 03 03 03 03 FF [URL] 00) = authenticated, avatar url will be supplied
                           (03 FF 03 02 03 01 FF [EMPTY] 00) = username valid, alias invalid, password valid, endianess cannot be empty
                           (03 FF 06 05 05 05 FF [EMPTY] 00) = user already validated, password, alias and endianess unchecked
    OR

    S4. bad username/password/endianess packet format
            packet format: [04]
                           [FF]
                           BAD
                           [00]
                           
                    bytes: (04 FF 42 41 44 00)                

OR

S5. server does not allow multi-user endpoint logins
       packet format: [05]
                      [FF]
                      BAD
                      [00]
                           
               bytes: (05 FF 42 41 44 00)    

// --------------------------------------------------
// new user registration

U6. register new user
		packet format: [06]
                       [FF]
                       [USERNAME]
                       [FF]
                       [BASE64 ENCODED PASSWORD]
                       [FF]
                       [EMAIL]
                       [00]
               
                bytes: (06 FF [..] FF [..] FF [..] 00)
                notes: EMAIL = required for password reset...

	REPLIES
        
    S7. valid, invalid or missing user registration 
            packet format: [07]
                           [FF]
                           [U 01|02|03|07]
                           [P 01|02|03|04|05]
                           [E 01|02|03|05]
                           [00]
                           
                    bytes: (07 FF 01|02|03|07 01|02|03|04|05 01|02|03|05 00)
                    notes: U = username field
                           possible values: 01 = empty field
                                            02 = invalid
                                            03 = okay
                                            07 = already in use

                           P = password field (base64 ecoding required)
                           possible values: 01 = empty field
                                            02 = invalid
                                            03 = okay
                                            04 = bad base 64 encode
                                            05 = unchecked
                           
                           E = email field
                           possible values: 01 = empty field
                                            02 = invalid
                                            03 = okay
                                            05 = unchecked
                           
                 examples: (03 FF 03 03 03 00) = user successfully registered
                           (03 FF 07 05 05 00) = username already in use, password unchecked, email unchecked
                           
              server duty: on valid, server needs to send an email containing a validation to the supplied mail account

    OR
    
    S8. bad user registration packet format
            packet format: [08]
                           [FF]
                           BAD
                           [00]
                           
                    bytes: (08 FF 42 41 44 00)

!END: ON TCP SOCKET CONNECT TO SERVER

!START: USER INFORMATION/UPDATE PACKETS

// --------------------------------------------------
// change alias from user

U9. change user alias
        packet format: [09]
                       [FF]
                       [NEW ALIAS]
                       [00]
                       
                bytes: (09 FF [..] 00)
                notes: this is handled per socket, not by user as multi-endpoint can cause confusion
                       so each socket endpoint within a user can have seperate aliases.
                       this won't matter if single endpoint is configured on the server.
                       
    REPLIES:
        
    S10. valid, invalid request to change user alias
    		packet format: [0A]
                           [FF]
                           [A 01|02|03|07]
                           [00]
                               
                    bytes: (0A FF 01|02|03|07 00)
                    notes: A = return code associated with the request to change user alias
                           possible values: 01 = empty field
                                            02 = invalid
                                            03 = okay
                                            07 = already in use
                                            
    OR
    
    S11. bad change alias packet format
            packet format: [0B]
                           [FF]
                           BAD
                           [00]
                           
                    bytes: (0B FF 42 41 44 00)
    

// --------------------------------------------------
// change alias from server

S12. update user alias
		packet format: [0C]
                       [FF]
                       [8-BYTE SOCKET KEY]
                       [FF]
                       [NEW ALIAS]
                       [00]
                               
                bytes: (0C FF [..] FF [..] 00)

// --------------------------------------------------
// seen user from user

U13. request when server last saw user
		packet format: [OD]
					   [FF]
					   [4-BYTE CLIENT ID]
					   [FF]
					   [USERNAME]
					   [00]
					   
                bytes: (0D FF [..] 00)
                
	REPLIES
	
	S14. valid, invalid request for seen format
			packet format: [OE]
						   [FF]
						   [4-BYTE CLIENT ID]
						   [FF]
						   [U 01|02|03]
						   [00]
						   
			        bytes: (0E FF [..] FF 01|02|03 00)
	        
	                notes: U = username field
	                       possible values: 01 = empty field
	                                        02 = invalid
	                                        03 = okay
	
	OR
	
	S15. bad seen request packet format
			packet format: [0F]
                           [FF]
                           BAD
                           [00]
                           
                    bytes: (0F FF 42 41 44 00)

// --------------------------------------------------
// seen user from server

S16. user last seen
		packet format: [10]
					   [FF]
					   [USERNAME]
					   [FF]
					   [13-BYTE TIMESTAMP] or NOW
					   [00]
					   
			    bytes: (10 FF [..] FF [..]|[4E 4F 57] 00)

// --------------------------------------------------
// set user away status from user

U17. set away status
		packet format: [11]
					   [FF]
                       [BASE64 ENCODED 64-BYTE MAX AWAY MESSAGE]
                       [00]

                bytes: (11 FF [..] 00)
                
                notes: [BASE64 ENCODED 64-BYTE MAX AWAY MESSAGE] can be empty

	S18. valid, invalid request for set away format
			packet format: [12]
						   [FF]
						   [AM 03|04|12]
						   [00]
				    
				    bytes: (12 FF 03|04|12 00)
				    
				    notes: AM = away message field
				           possible values: 03 = okay
				           	                04 = bad base64 encode
				           	                12 = message body too long
		
	S19. bad seen request packet format
			packet format: [13]
                           [FF]
                           BAD
                           [00]
                           
                    bytes: (13 FF 42 41 44 00)

// --------------------------------------------------
// set user away status from server

S20. set away status
		packet format: [14]
					   [FF]
					   [8-BYTE SOCKET ID]
					   [FF]
					   [BASE64 ENCODED 64-BYTE MAX AWAY MESSAGE]
					   [00]

                bytes: (14 FF [..] FF [..])
                
                notes: [BASE64 ENCODED 64-BYTE MAX AWAY MESSAGE] can be empty

!END: USER INFORMATION/UPDATE PACKETS

//----------------------------------------------------
//PACKETS 17-39 are reserved...
//to sort out the rest of this missing user packets
//----------------------------------------------------

// --------------------------------------------------
// user logged off from user

U40. log off server
        packet format: [28]
                       [00]
                      
                bytes: (28 00)
                notes: server will close connection cleanly
                       connections should attempt to use this whenever possible

// --------------------------------------------------
// user logged off from server

S41. user logged off from server
		packet format: [29]
		               [FF]
		               [8-BYTE SOCKET KEY]
		               [00]
		               
		        bytes: (29 FF [..])
                       
//----------------------------------------------------
//PACKETS 42-79 are reserved...
//to sort out the rest of this missing user packets
//----------------------------------------------------

// NOTES ON IDENTIFIERS USED FOR MESSAGING

16-BYTE UNIQUE ID
   - 1st 8-bytes of an incremental counter controlled by the server
   - 2nd 8-bytes follow http://www.w3schools.com/jsref/jsref_gettime.asp

8-BYTE UNIQUE ROOM ID
   - ROOM ID ("00000000") is always used for global message broadcast
   - ROOM ID ("0000ECHO") is always used for echo packet testing
   - incremental room counter to prevent collisions on logs

4-BYTE CLIENT MESSAGE ID
   - Session only.
   - Can reset on reconnect.
   - Clients can recycle ID's as the server does not validate their uniqueness.
   - The server will assign new ID's to all valid packets for retransmission.
   - These only matter for replies to the client when something goes wrong so
     the client can identify the packet.
   
!START: SHORT MESSAGING PACKETS

// --------------------------------------------------
// short message from user

U80. short chat message
        packet format: [50]
                       [FF]
                       [4-BYTE CLIENT MESSAGE ID]
                       [FF]
                       [8-BYTE UNIQUE ROOM ID]
                       [FF]
                       [MESSAGE BASE64 ENCODED 4000 BYTE MAX]
                       [00]
                        
                bytes: (50 FF [..] FF [..] FF [..] 00)

    REPLIES

    S81. valid, invalid or missing short chat message packet data
             packet format: [51]
                            [FF]
                            [4-BYTE CLIENT MESSAGE ID]
                            [FF]
                            [RID 01|02|03|09]
                            [M 01|03|04|11|12]
                            [00]
                            
                     bytes: (51 FF [..] FF 01|02|03|09 01|03|04|11|12 00)
                     notes: RID = unique room id field
                            possible values: 01 = empty field
                                             02 = invalid
                                             03 = okay                                             
                                             09 = not in that room
                        
                            M = messge body field
                            possible values: 01 = empty field
                                             03 = okay
                                             04 = bad base 64 encode
                                             11 = empty message
                                             12 = message body too long

    OR
    
    S82. bad short chat message format
            packet format: [52]
                           [FF]
                           BAD
                           [00]
                           
                    bytes: (52 FF 42 41 44 00)
                    notes: this packet is virtually useless, client won't know
                           what message is attached to. it's just a general...
                           you really messed up sending a packet of this type.
    

// --------------------------------------------------
// short message from server
    
S83. short chat message
         packet format: [53]
                        [FF]
                        [16-BYTE UNIQUE ID]
                        [FF]
                        [8-BYTE UNIQUE ROOM ID]
                        [FF]
                        [8-BYTE SOCKET KEY]
                        [FF]
                        [MESSAGE BASE64 ENCODED 4000 BYTE MAX]
                        [00]
                        
                 bytes: (53 FF [..] FF [..] FF [..] FF [..] FF [..] 00)
                                  
    REPLIES
    
    U84. short chat message received
             packet format: [54]
                            [FF]
                            [16-BYTE UNIQUE ID]
                            [FF]
                            [8-BYTE UNIQUE ROOM ID]                        
                            [00]
                            
                     bytes: (54 FF [..] FF [..] 00)
                     
        REPLIES
        
        S85. bad short chat message received reply
                 packet format: [55]
                                [FF]
                                [16-BYTE UNIQUE ID]
                                [00]
                                                                
                         bytes: (55 FF [..] 00)
                         notes: only used if reply didn't match a valid message
                                on ack. debug packet only.                       
                         
        OR
        
        S86. bad short chat message received reply
                 packet format: [56]
                                [FF]
                                BAD
                                [00]
                                
                         bytes: (56 FF 42 41 44 00)
                         notes: this packet is virtually useless, client won't
                                know what message is attached to. it's just a
                                general... you really messed up sending a packet
                                of this type.

!END: SHORT MESSAGING PACKETS

!START: LONG MESSAGING PACKETS

// --------------------------------------------------
// long message head from user

U87. long chat message head
         packet format: [57]
                        [FF]
                        [TP 4-bytes]
                        [FF]
                        [4-BYTE CLIENT MESSAGE ID]
                        [FF]
                        [8-BYTE UNIQUE ROOM ID]
                        [FF]
                        [MESSAGE BASE64 ENCODED 4000 BYTE MAX]
                        [00]
                        
                 bytes: (57 [FF] [..] FF [..] FF [..] FF [..] 00)
                 notes: TP [UINT32] = number of remaining packets [1..X]

    REPLIES

    S88. valid, invalid, missing long chat message head packet data
             packet format: [58]
                            [FF]
                            [4-BYTE CLIENT MESSAGE ID]
                            [FF]                            
                            [TP 01|02|03|05]                            
                            [CID 03|13]
                            [RID 01|02|03|05|08|09]
                            [M 01|03|04|05|11|12]
                            [00]
                            
                     bytes: (58 FF [..] FF 01|02|03|05 03|13 01|02|03|04|05|09 01|03|04|05|11|12 00)
                     notes: TP = number of remaning packets field
                            possible values: 01 = empty field
                                             02 = invalid
                                             03 = okay
                                             05 = unchecked
                                                        
                            CID = client message ID field
                            possible valies: 03 = okay
                                             13 = existing long message pending                                               
                                                        
                            RID = uniqie room id field
                            possible values: 01 = empty field
                                             02 = invalid
                                             03 = okay
                                             05 = unchecked                                             
                                             09 = not in that room
                        
                            M = messge body field
                            possible values: 01 = empty field
                                             03 = okay
                                             04 = bad base 64 encode
                                             05 = unchecked
                                             11 = empty message
                                             12 = message body too long

    OR
    
    S89. bad long chat message head packet format
            packet format: [59]
                           [FF]
                           BAD
                           [00]
                           
                    bytes: (59 FF 42 41 44 00)
                    notes: this packet is virtually useless, client won't know
                           what message is attached to. it's just a general...
                           you really messed up sending a packet of this type.

// --------------------------------------------------
// long message next from user

U90. long chat message next
         packet format: [5A]
                        [FF]
                        [PN 4 bytes]
                        [FF]
                        [HEAD 4-BYTE CLIENT MESSAGE ID]
                        [FF]                        
                        [8-BYTE UNIQUE ROOM ID]
                        [FF]
                        [MESSAGE BASE64 ENCODED 4000 BYTE MAX]
                        [00]
                        
                 bytes: (5A FF [..] FF [..] FF [..] FF [..] 00)
                 notes: PN [UINT32] = packet # 

    REPLIES

    S91. valid, invalid, missing long chat message next packet data
             packet format: [5B]
                            [FF]
                            [HEAD 4-BYTE CLIENT MESSAGE ID]
                            [FF]
                            [PN 01|02|03]
                            [CID 03|13]                            
                            [RID 01|02|03|09]
                            [M 01|03|04|11|12]
                            [00]
                            
                     bytes: (5B FF [..] FF 01|02|03 03|13 01|02|03|09 01|03|04|11|12 00)
                     notes: PN = packet #
                            possible values: 01 = missing
                                             02 = invalid
                                             03 = okay
							
							CID = client message ID field
                            possible valies: 03 = okay
                                             13 = existing long message pending                                               
                                                        
                            RID = uniqie room id field
                            possible values: 01 = missing
                                             02 = invalid
                                             03 = okay                                             
                                             09 = not in that room
                        
                            M = messge body field
                            possible values: 01 = empty field
                                             03 = okay
                                             04 = bad base 64 encode
                                             11 = empty message
                                             12 = message body too long
     
    OR

    S92. bad long chat message next packet format
            packet format: [5C]
                           [FF]
                           BAD
                           [00]
                           
                    bytes: (5D FF 42 41 44 00)
                    notes: this packet is virtually useless, client won't know
                           what message is attached to. it's just a general...
                           you really messed up sending a packet of this type.
     
POSSIBLE REPLIES
     
S93. resend long chat message next packet
		packet format: [5D]
                       [FF]
                       [PN 4 bytes]
                       [FF]
                       [4-BYTE CLIENT MESSAGE ID]
                       [00]
                            
                bytes: (5D FF [..] FF [..] 00)
                notes: PN [UINT32] = packet # 

// --------------------------------------------------
// long message head from server

S94. long chat message head
         packet format: [5E]
                        [FF]
                        [TP 4-BYTE]
                        [FF]
                        [16-BYTE UNIQUE ID]
                        [FF]
                        [8-BYTE UNIQUE ROOM ID]
                        [FF]
                        [8-BYTE SOCKET KEY]
                        [FF]
                        [MESSAGE BASE64 ENCODED 4000 BYTE MAX]
                        [00]
                        
                 bytes: (5E [FF] [..] FF [..] FF [..] FF [..] FF [..] FF [..] 00)
                 notes: TP [UINT32] = number of remaining packets [1..X]

    POSSIBLE REPLIES [THESE ARE NOT MANDATORY RESPONSES FROM THE USER]
    
    U95. long chat message head received
             packet format: [5F]
                            [FF]
                            [16-BYTE UNIQUE ID]
                            [FF]
                            [8-BYTE UNIQUE ROOM ID]
                            [00]
                            
                     bytes: (5F FF [..] FF [..] 00)
                     
        REPLIES
        
        S96. bad long chat message head received reply
                 packet format: [60]
                                [FF]
                                [16-BYTE UNIQUE ID]
                                [FF]
                                [8-BYTE UNIQUE ROOM ID]                        
                                [00]
                                
                         bytes: (60 FF [..] FF [..] 00)
                         notes: only used if reply didn't match a valid message
                                on ack. debug packet only.
                                
        OR
        
        S97. bad long chat message head recieved reply
            	packet format: [61]
                	           [FF]
                    	       BAD
                        	   [00]
                           
                    	bytes: (61 FF 42 41 44 00)
                    	notes: this packet is virtually useless, client won't know
                        	   what message is attached to. it's just a general...
                           	   you really messed up sending a packet of this type.

// --------------------------------------------------
// long message next from server

S98. long chat message next
         packet format: [62]
                        [FF]
                        [PN 4 bytes]
                        [FF]
                        [16-BYTE UNIQUE ID]
                        [FF]
                        [8-BYTE UNIQUE ROOM ID]                        
                        [FF]
                        [MESSAGE BASE64 ENCODED 4000 BYTE MAX]
                        [00]
                        
                 bytes: (62 FF [..] FF [..] FF [..] FF [..] 00)
                 notes: PN [UINT32] = packet # 

POSSIBLE REPLIES

U99. resend long chat message next packet
         packet format: [63]
                        [FF]
                        [PN 4 bytes]
                        [FF]
                        [16-BYTE UNIQUE ID]                            
                        [FF]
                        [8-BYTE UNIQUE ROOM ID]
                        [00]
                            
                 bytes: (63 FF [..] FF [..] FF [..] 00)
                 notes: PN [UINT32] = packet # 

    REPLIES
        
    S100. valid, invalid, missing resend long chat message next packet data
             packet format: [64]
                            [FF]
                            [16-BYTE UNIQUE ID]
                            [FF]
                            [PN 01|02|03]
                            [RID 01|02|03|08|09]
                            [M 01|02|03]                            
                            [00]
                                
                     bytes: (64 FF [..] FF 01|02|03 01|02|03|08|09 01|02|03 00)
                     notes: PN = packet #
                            possible values: 01 = empty field
                                             02 = invalid
                                             03 = okay
                            
                            RID = unique room id field
                            possible values: 01 = empty field
                                             02 = invalid
                                             03 = okay
                                             08 = not authorized
                                             09 = not in that room
                                                 
                            M = messge body field
                            possible values: 01 = empty field
                                             02 = invalid
                                             03 = okay                                             
                                                                
    OR

    S101. bad resend long chat message next packet format
             packet format: [65]
                            [FF]
                            [PN 4 bytes]
                            [FF]
                            [16-BYTE UNIQUE ID]
                            [FF]
                            [8-BYTE UNIQUE ROOM ID]                            
                            [00]
                                
                     bytes: (65 FF [..] FF [..] FF [..] 00)
                     notes: only used if reply didn't match a valid message
                            on ack. debug packet only. 
        
    OR
        
    S102. bad resend long chat message next packet format
             packet format: [66]
                            [FF]
                            BAD
                            [00]
                                
                     bytes: (66 FF 42 41 44 00)
                     notes: this packet is virtually useless, client won't
                            know what message is attached to. it's just a
                            general... you really messed up sending a packet
                            of this type.

!END: LONG MESSAGING PACKETS

//----------------------------------------------------
//PACKETS 103-159 are reserved...
//to sort out the rest of this missing messaging packets
//----------------------------------------------------

!START: ROOM ACCESS JOIN, PART AND INVITE

// --------------------------------------------------
// join room from user

U160. join room
        packet format: [A0]
                       [FF]
                       [8-BYTE UNIQUE ROOM ID]
                       [FF]
                       [BASE64 ENCODED PASSWORD]
                       [00]
                       
                bytes: (A0 FF [..] FF [..] 00)
                notes: when joining a room you can leave the password blank
                       this field is only needed for rooms that are password
                       protected.
        
        server duties: if a room does not exist, create a default room with
                       transient state for the user to join.  follows IRC.
                       the room can then be state changed by the first user
                       that joined the room or appointed moderators. first
                       user is always the room owner.
        
    REPLIES:
                       
    S161. valid, invalid join room request
            packet format: [A1]
                           [FF]
                           [8-BYTE UNIQUE ROOM ID]
                           [FF]
                           [RID 01|02|03|08|09|10]
                           [00]
                               
                    bytes: (A1 FF [..] FF 01|02|03|08|09|10 00)
                    notes: RID = unique room id field
                           possible values: 01 = empty field
                                            02 = invalid
                                            03 = okay
                                            08 = not authrized
                                            09 = not in that room
                                            10 = already in that room
                                                
	OR

	S162. bad join room request packet format
			packet format: [A2]
                           [FF]
                           BAD
                           [00]
                                
                    bytes: (A2 FF 42 41 44 00)
                    notes: this packet is virtually useless, client won't know
                           what message is attached to. it's just a general...
                           you really messed up sending a packet of this type.

// --------------------------------------------------
// join room from server

S163. user joined room
        packet format: [A3]
                       [FF]
                       [8-BYTE UNIQUE ROOM ID]
                       [FF]
                       [8-BYTE SOCKET KEY]
                       [FF]
                       [USERNAME]
                       [FF]
                       [ALIAS]
                       [00]
                               
                bytes: (A3 FF [..] FF [..] FF [..] FF [..] 00)
                
// --------------------------------------------------
// part room from user
        
U164. part room
        packet format: [A4]
                       [FF]
                       [8-BYTE UNIQUE ROOM ID]
                       [FF]
                       [BASE64 ENCODED 4000-BYTE MAX PARTING MESSAGE]
                       [00]
                       
                bytes: (A4 FF [..] FF [..] 00)
        
	REPLIES
                       
    S165. valid, invalid part room request
            packet format: [A5]
                           [FF]
                           [8-BYTE UNIQUE ROOM ID]
                           [FF]
                           [RID 01|02|03|09]
                           [PM 02|03|04|05|12]
                           [00]
                               
                    bytes: (A5 FF [..] FF 01|02|03|09 00)
                    notes: RID = unique room id field
                           possible values: 01 = empty field
                                            02 = invalid
                                            03 = okay
                                            09 = not in that room

						   PM = part message field
						   possible values: 02 = invalid
                                            03 = okay
                                            04 = bad base65 encode
                                            05 = unchecked
                                            12 = message body too long

	OR
		
	S166. bad part room packet format
			packet format: [A6]
                           [FF]
                           BAD
                           [00]
                                
                    bytes: (A6 FF 42 41 44 00)
                    notes: this packet is virtually useless, client won't know
                           what message is attached to. it's just a general...
                           you really messed up sending a packet of this type.

// --------------------------------------------------
// part room from server

S167. user parted room
        packet format: [A7]
                       [FF]
                       [8-BYTE UNIQUE ROOM ID]
                       [FF]
                       [8-BYTE SOCKET KEY]
                       [FF]
                       [BASE64 ENCODED 4000-BYTE MAX PARTING MESSAGE]                       
                       [00]
                               
                bytes: (A7 FF [..] FF [..] FF [..] 00)

// --------------------------------------------------
// invite user to room from user

U168. invite user to room
        packet format: [A8]
                       [FF]
                       [4-BYTE CLIENT MESSAGE ID]
                       [FF]
                       [8-BYTE UNIQUE ROOM ID]
                       [FF]
                       [USERNAME]
                       [FF]                       
                       [8-BYTE SOCKET KEY]
                       [00]
                       
                bytes: (A8 FF [..] FF [..] FF [..] 00)
                notes: Only [USERNAME] or [8-BYTE SOCKET KEY] need to be
                       supplied.
                       
                       if [8-BYTE SOCKET KEY] is left blank then all
                       endpoints associated with username should be sent
                       the invite or if [8-BYTE SOCKET KEY] is specified,
                       only that specific endpoint.  
                       
	REPLIES:
		
	U169. valid, invalid invite user to room request
    		packet format: [A9]
                           [FF]
                           [4-BYTE CLIENT MESSAGE ID]                           
                           [FF]                      
                           [RID 01|02|03|08|09]
                           [U 01|02|03|14|15]
                           [00]
                               
                    bytes: (A9 FF [..] FF 01|02|03|08|09 01|02|03|14|15 00)
                    notes: RID = unique room id field
                           possible values: 01 = empty field
                                            02 = invalid
                                            03 = okay
                                            08 = not authorized
                                            09 = not in that room
                    
                    	   U = username/alias fields
                    	   possible values: 01 = empty field
                                            02 = invalid
                                            03 = okay
                                            14 = bad user
                                            15 = auto-rejected

	U170. bad invite user to room packet format
			packet format: [AA]
			               [FF]
				           BAD
				           [00]
				               
		            bytes: (AA FF 42 41 44 00)
                    notes: this packet is virtually useless, client won't know
                           what message is attached to. it's just a general...
                           you really messed up sending a packet of this type.

// --------------------------------------------------
// invite user to room from server

S171. invite user to room
        packet format: [AB]
                       [FF]                                              
                       [8-BYTE UNIQUE ROOM ID]
                       [FF]
                       [BASE64 ENCODED PASSWORD]
                       [FF]
                       [ORIGIN 8-BYTE SOCKET ID]                       
                       [00]
                       
                bytes: (AB FF [..] FF [..] FF [..] FF [..] 00)
                NOTES: [BASE64 ENCODED PASSWORD] can be empty
          
!END: ROOM ACCESS JOIN, PART AND INVITE

!START: ROOM INFORMATION

// --------------------------------------------------
// send room settings from server

U172. user requesting room listing
		packet format: [AC]
					   [00]

                bytes: (AC 00)

// --------------------------------------------------
// send room settings from server

S173. send room settings/details
		packet format: [AD]
					   [FF]					   					   
					   [RT P|T]
					   [IL T|F]
					   [PVT T|F]
					   [PWD T|F]					   
					   [FF]
					   [8-BYTE ROOM ID]
					   [FF]
					   [BASE64 ENCODED 256-BYTE MAX TITLE]
					   [FF]
					   [BASE64 ENCODED 512-BYTE MAX DESCRIPTION]
					   [FF]
					   [ROOM CREATED 8-BYTE TIMESTAMP]					   
					   [FF]
					   [ROOM OWNER]
					   [FF]
					   [USERLIMIT]
					   [FF]
					   [USER COUNT]
					   [FF]
					   [2-BYTE MODERATOR COUNT]
					   [FF]
					   
					   [MODERATOR USERNAME]
					   [??]
					   					   			   					   
					   [00]

                bytes: (AD ........ 00) // TODO: complete...

				notes: [RT] = room type field
					   possible values: P = permanent
					                    T = transient
					                    
					   [IL] = is logged field
					   possible values: T = TRUE
					                    F = FALSE

					   [PVT] = is private field
					   possible values: T = TRUE
					                    F = FALSE
					                    
					   [PWD] = is password protected field
					   possible values: T = TRUE
					                    F = FALSE
					   
					   [USER COUNT] = current users in the room
					   possible values: [000000-999999]
					   
					   [2-BYTE MODERATOR COUNT] = count of moderator records following
					   posisble values: [00-99]
					                    
					   [??] = [MODERATOR] and [PRIVILEGES] fields will repeat
					          based on the total number of moderator records.
		 
		 server notes: this packet should only display public rooms to standard users
		               with private rooms only being exposed to admins, room owners
		               and room moderators.  meaning only fire off packets a user
		               should be aware off.

// --------------------------------------------------
// send user list for a room from server

S174. send user list
		packet format: [AE]
					   [FF]
					   [8-BYTE UNIQUE ROOM ID]
                       [FF]
                       [1-BYTE]
                                              				   
					   [USERNAME]
                       [FF]
                       [ALIAS]
                       [FF]
                       [8-BYTE SOCKET KEY]
                       [FF]
                       [PRIVILEGES]
                       [FF]
                       [A T|F]
                       [FF]
                       [BASE64 ENCODED 64-BYTE MAX AWAY MESSAGE]                                              
                       [??]
                       
                       [00]
                       
                bytes: (AE FF [..] FF [..] [??] 00)
                
                notes: [ALIAS] can be empty
                
                       [PRIVILEGES] can be empty
                       
                       [BASE64 ENCODED 64-BYTE MAX AWAY MESSAGE] can be empty
                
                       [A] = user is away
                       possible values: T = true
                                        F = false
                                
                       [M] = user is muted
                       possible values: T = true
                                        F = false
                
                       [??] = username and alias will repeat until the packet is full or all user are serialized.
                              more than one packet of this type can be sent if the user list is large.  there is
                              no unique packet number system with these as the order doesn't matter.

!END: ROOM ACCESS, ADMIN AND OTHER CONTROL PACKETS







------------------------------------

[unclean]


251. [server] packet not supported
packet format: [FB][FF]BAD[00]
        bytes: (FB FF 42 41 44 00)

252. [user] request list of server supported packets
packet format: [FC][FF]SP[00]
        bytes: (FC FF 53 50 00)

253. [server] servers supports these packets
packet format: [FD][FF][XX][...][00]
       bytes: (FE FF XX [..] 00)
       NOTES: XX in this case represents a packet the server supports.
              [..] alots that they should follow [FF][XX] for other packets that are supported

254. [user] client supports these packets
packet format: [FE][FF][XX][...][00]
       bytes: (FE FF XX [..] 00)
       NOTES: XX in this case represents a packet the client supports.
              [..] alots that they should follow [FF][XX] for other packets that are supported

255. used as the delimiter for packet fields




//--------------------------------------------------------------
//--------------------------------------------------------------
//--------------------------------------------------------------
// PAST THIS POINT IS ALL NOTES...
// UNFINISHED PACKETS AND THINGS TO BE IMPLEMENTED
//--------------------------------------------------------------
//--------------------------------------------------------------
//--------------------------------------------------------------

when user joins the server after validation

a list of users... 

isMuted
  packets will also need to fire for these events
  
  -muted user added
  -muted user removed

isFriend
  packets will also need to fire for these events

  -friend added
  -friend removed

used only when a user connects to a room and server sends userlist
or I guess when a user joins a room... these should also be
updateable states... packets will need to be defined for each of these

isAdmin
isGlobalMod
isRoomOwner
isRoomMod
isAway

isPunished
  - punishment
  - ulong timestamp ending

--------------------------------------------



//
//need validation for email
//social/media links optional 
//GENDER = [01 = Male|02 = Female|03 = Trans|04 = Other|05 = Mayo]
//DOB = date of birth [MM/DD/YY], NAME [optional but [FF] delimiters must still mark the empty fields]
//[FF][EMAIL][FF][GENDER][FF][DOB][FF][NAME]

// [user] update user information
//packet format: [03][FF][BASE64ENCODED PASSWORD[FF][EMAIL ADDRESS][FF]M|F|T|O[FF][DOB MM/DD/YY][FF][NAME][00]
//        bytes: (03 FF [..] [FF] [..] [FF] 4D|46|54|4F [..] FF [..] 00)
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
//        bytes: (05 [FF] [..] FF [..] 00)
//        NOTES: 4 byte encoded UINT32 marks the number of remaning packets [1..X]
//.  [user] send user avatar.png next
//packet format: [06][FF][XX][FF][BASE64ENCODED 4000 BYTE MAX][00]
//        bytes: (06 FF XX FF [..] 00)
//       NOTES: XX is the packet #
//  [server] send user avatar.png head
//packet format: [07][FF][4 bytes][FF][BASE64ENCODED 4000 BYTE MAX][00]
//        bytes: (07 [FF] [..] FF [..] 00)
//       NOTES: 4 byte encoded UINT32 marks the number of remaning packets [1..X]
//  [server] send user avatar next
//packet format: [08][FF][XX][FF][BASE64ENCODED 4000 BYTE MAX][00]
//        bytes: (08 FF XX FF [..] 00)
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
//        bytes: (0B FF [..] 00)
//
//33. [user] unfriend user
//packet format: [0C][FF][USERNAME][00]
//        bytes: (0C FF [..] 00)
// [user] silence user
//packet format: [0D][FF][USERNAME][FF][REASON][FF][MINUTES][FF][HOURS][FF][DAYS][FF][MONTHS][FF][YEARS][00]
//        bytes: (0D FF [..] FF [..] FF [0..59] FF [0..23] FF [0..11] FF [0..255] 00)
//        NOTES: if no time spans are given a default of 15 minutes is assumed.      
// [server] not authorized to silence users
//packet format: [0E][FF]SU[00]
//        bytes: (0E FF 53 55 00)        
// [user] ban user
//packet format: [0F][FF][USERNAME][FF][REASON][FF][MINUTES][FF][HOURS][FF][DAYS][FF][MONTHS][FF][YEARS][00]
//       bytes: (0F FF [..] FF [..] FF [0..59] FF [0..23] FF [0..11] FF [0..255] 00)
//     NOTES: if no time spans are given a default of 3 hours is assumed.        
// [server] not authorized to ban users
//packet format: [10][FF]BU[00]
//        bytes: (10 FF 42 55 00)
// [user] unban user
//packet format: [11][FF][USERNAME][00]
//        bytes: (11 FF [..] 00)
// [server] not authorized to uban users
//packet format: [12][FF]UU[00]
//        bytes: (12 FF 55 55 00)
// user has gone offline
// user has come online










55. [user] move message from room to room
packet format: [0A][FF][8-byte UNIQUE ROOM ID][FF][16-byte UNIQUE ID][00]
        bytes: (0A FF [..] [FF] [..] 00)

22. [server] room created
packet format: [16][FF][8-byte UNIQUE ROOM ID][00]
        bytes: (16 FF [..] 00)
        NOTES: user should be informed they need to configure the room before others can join it.


24. [user] configure room settings

25. [server] not authorized to change room settings

24. [user] leave a room
packet format : [15][FF][8-byte UNIQUE ROOM ID]


```
