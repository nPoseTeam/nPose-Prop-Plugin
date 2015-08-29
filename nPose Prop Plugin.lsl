/*
The nPose scripts are licensed under the GPLv2 (http://www.gnu.org/licenses/gpl-2.0.txt), with the following addendum:

The nPose scripts are free to be copied, modified, and redistributed, subject to the following conditions:
    - If you distribute the nPose scripts, you must leave them full perms.
    - If you modify the nPose scripts and distribute the modifications, you must also make your modifications full perms.

"Full perms" means having the modify, copy, and transfer permissions enabled in Second Life and/or other virtual world platforms derived from Second Life (such as OpenSim).  If the platform should allow more fine-grained permissions, then "full perms" will mean the most permissive possible set of permissions allowed by the platform.
*/
//to set a prop to explicit, add |explicit to the end of PROP line in notecard, else prop will be a normal prop
//to have prop explicitly die, send propname=die in notecard parm spot #2
// PROP|propname|propname=die

float timeout = 10.0;
rotation rot;
vector pos;
key parent = NULL_KEY;
integer chatchannel;
integer dietimeout;
integer timeoutticker =0;
string lifetime;
//string timeToLive;
integer iMoved = 0;
string sFilter = ""; //this filters out duplicate messages.  
integer explicitFlag;
integer sFilter1;
vector vDelta;



string timeToLive(){
    string desc = (string)llGetObjectDetails(llGetKey(), [OBJECT_DESC]);
    //prim desc will be elementtype~notexture(maybe)
    list params = llParseString2List(desc, ["~"], []);
    integer n;
    integer stop = llGetListLength(params);
    for (n=0; n<stop; n++){
        list param = llParseString2List(llList2String(params,n), ["="], []);
        if (llList2String(param,0) == "lifetime"){
            lifetime = llList2String(param, 1);
        }
    }
    if (lifetime =="" || lifetime == "0"){
        return "0";
    }else{
        return lifetime;
    }
}

default{
    //any script inside a prop can link message into this prop plugin and have it relay messages to the nPose system.
    //the core is expecting specificly a string like this:  "PROPRELAY|arbNum|message|toucherKey"
    //this prop script doesn't care what num is, it will be looking for the first 9 characters in the str to be "PROPRELAY"
    //we need to provide the other info that the core is looking for to process messages.
    link_message(integer sender, integer num, string str, key id){
        if (llGetSubString(str,0,8) == "PROPRELAY"){
            llRegionSayTo(parent, chatchannel, str);
        }
        
    }
    
    on_rez(integer param){
        parent = NULL_KEY;
        iMoved = 0;
        if (param){
            explicitFlag = 0;
            sFilter1 = 0;
            pos = llGetPos();
            rot = llGetRot();
            chatchannel = param;
            dietimeout = (integer)timeToLive();
            llListen(chatchannel, "", "", "");
            llSetTimerEvent(timeout);
            llRegionSay(chatchannel, "ping");
        }else{
            llSetTimerEvent(0.0);
        }
    }

    listen(integer channel, string name, key id, string message){
        list msg = llParseString2List(message, ["|"], []);
        string cmd = llList2String(msg,0);
        list params1 = llParseString2List(cmd, ["="],[]);
        if ((llList2String(params1,0) == llGetObjectName()) && (llList2String(params1,1) == "die") && (explicitFlag == 1)){
            llDie();
        }else if (cmd == "die" && explicitFlag == 0){
            llDie();
        }
        if (llGetOwnerKey(id) == llGetOwner()){
            if (cmd == "posdump"){
                string out = (string)pos + "|" + (string)rot;
                if (explicitFlag == 1){ out = out + "|explicit";}
                if (parent){
                    llRegionSayTo(parent, chatchannel, out);
                }else{
                    llRegionSay(chatchannel, out);
                }
            }
            else if (cmd == "pong"){
                if (sFilter1 == 0){
                    explicitFlag = (integer)llList2String(msg, 1);
                    parent = id;
                    vDelta = (vector)llList2String(msg, 2);
                    sFilter1 = 1;
                }
                if (parent == NULL_KEY){
                    parent = id;
                }
            }else if (cmd == "LINKMSG"){
                llMessageLinked(LINK_SET,(integer)llList2String(msg,1),llList2String(msg,2),(key)llList2String(msg,3));
            }else if (cmd == "LINKMSGQUE"){
                if (message != sFilter){
                    //filter out duplicates
                    llMessageLinked(LINK_SET,(integer)llList2String(msg,1),llList2String(msg,2),(key)llList2String(msg,3));
                    sFilter = message;
                }
            }else if (cmd == "MOVEPROP" ){
                if (llList2String(msg,1) == llGetObjectName() && (llVecMag(vDelta) < 0.1)){
                    if (iMoved == 0){
                        // move it
                        vector vPosition =  (vector)llList2String(msg,2);
                        llSetRegionPos( vPosition );
                        pos = llGetPos();
                        rot = llGetRot();
                    }
                    iMoved = 1;
                }
            }
        }
    }

    timer(){
        timeoutticker = timeoutticker+10;
        if (parent != NULL_KEY){
            if (dietimeout !=0){
                if (llKey2Name(parent) == "" || timeoutticker >= dietimeout){
                    llDie();
                }
            }else if (llKey2Name(parent) == ""){
                llDie();
            }
        }
        integer chat_out = FALSE;
        if (llGetPos() != pos){
            pos = llGetPos();
            chat_out = TRUE;
        }
        if (llGetRot() != rot){
            rot = llGetRot();
            chat_out = TRUE;
        }
        if (chat_out){
            string out = (string)pos + "|" + (string)rot;
            if (explicitFlag == 1){ out = out + "|explicit";}
            if (parent){
                llRegionSayTo(parent, chatchannel, out);
            }else{
                llRegionSay(chatchannel, out);
            }
        }
    }
}
