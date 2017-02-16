/*
The nPose scripts are licensed under the GPLv2 (http://www.gnu.org/licenses/gpl-2.0.txt), with the following addendum:

The nPose scripts are free to be copied, modified, and redistributed, subject to the following conditions:
    - If you distribute the nPose scripts, you must leave them full perms.
    - If you modify the nPose scripts and distribute the modifications, you must also make your modifications full perms.

"Full perms" means having the modify, copy, and transfer permissions enabled in Second Life and/or other virtual world platforms derived from Second Life (such as OpenSim).  If the platform should allow more fine-grained permissions, then "full perms" will mean the most permissive possible set of permissions allowed by the platform.
*/

float TICKER_TIME = 10.0;
float DEFAULT_TIMEOUT = 10.0;
string PROP_REZ_COMMAND="PROP";

rotation MyRot;
vector MyPos;
key Parent = NULL_KEY;
integer ChatChannel;
float Lifetime;
//string Filter = ""; //this filters out duplicate messages.  
integer MyGroup;
integer QuietMode;

debug(list message){
    llOwnerSay((((llGetScriptName() + "\n##########\n#>") + llDumpList2String(message,"\n#>")) + "\n##########"));
}

float timeToLive(){
    //Leona: AFAIK: This isn't documented. Does someone use this?
    float lifetime;
    string desc = (string)llGetObjectDetails(llGetKey(), [OBJECT_DESC]);
    //prim desc will be elementtype~notexture(maybe)
    list params = llParseString2List(desc, ["~"], []);
    integer n;
    integer stop = llGetListLength(params);
    for (n=0; n<stop; n++){
        list param = llParseString2List(llList2String(params,n), ["="], []);
        if (llList2String(param,0) == "lifetime"){
            lifetime = (float)llList2String(param, 1);
        }
    }
    return lifetime;
}

report() {
    if(Parent!=NULL_KEY) {
        //if we have a parent we use relative pos and rot
        list parentDetails=llGetObjectDetails(Parent, [OBJECT_POS, OBJECT_ROT]);
        vector parentPos=llList2Vector(parentDetails, 0);
        rotation parentRot=llList2Rot(parentDetails, 1);
        
        vector reportingPos = (llGetPos() - parentPos) / parentRot;
        vector reportingRot = llRot2Euler(llGetRot() / parentRot) * RAD_TO_DEG;
        
        list parts = [PROP_REZ_COMMAND, llGetObjectName(), reportingPos, reportingRot];
        if(QuietMode) {
            parts+=[(string)MyGroup, "quiet"];
        }
        else if(MyGroup) {
            parts+=[(string)MyGroup];
        }
        llRegionSayTo(llGetOwner(), 0, llDumpList2String(parts, "|"));
    }
    else {
        //should we do anything if we don't have a parent?
    }
}

execute(list msg, key id) {
    string cmd=llList2String(msg, 0);
    if(cmd == "posdump") {
        report();
    }
    else if(cmd == "pong") {
        if(Parent == NULL_KEY) {
            Parent = id;
        }
    }
    else if(cmd == "LINKMSG") {
        llMessageLinked(LINK_SET,(integer)llList2String(msg,1),llList2String(msg,2),(key)llList2String(msg,3));
    }
/* added for Yvana, temporary disabled because it have to be rewritten (the message is not known inside this function
    else if(cmd == "LINKMSGQUE") {
        if(message != Filter) {
            //filter out duplicates
            llMessageLinked(LINK_SET,(integer)llList2String(msg,1),llList2String(msg,2),(key)llList2String(msg,3));
            Filter = message;
        }
    }
*/
    else if(cmd == "MOVEPROP" ) {
        //moveprop only works for a short period from the time the prop rezzes until it gets its parent
        if(Parent==NULL_KEY) {
            if(llList2String(msg,1) == llGetObjectName()) {
                // move it
                llSetRegionPos((vector)llList2String(msg,2));
                MyPos = llGetPos();
                MyRot = llGetRot();
                Parent = id;
            }
        }
    }
    else if(cmd=="PROPDIE") {
        // PROPDIE[|propNameList[|propGroupList]]
        string myName=llGetObjectName();
        string targetNamesString=llList2String(msg, 1);
        string targetGroupsString=llList2String(msg, 2);
        
        integer nameMatch = targetNamesString=="" || targetNamesString=="*";
        integer groupMatch = targetGroupsString=="" || targetGroupsString=="*";

        //group check
        if(!groupMatch) {
            list targetGroups=llCSV2List(targetGroupsString);
            if(~llListFindList(targetGroups, [(string)MyGroup])) {
                groupMatch=TRUE;
            }
        }

        //Name check
        if(groupMatch && !nameMatch) {
            list targetNames=llCSV2List(targetNamesString);
            while(llGetListLength(targetNames) && !nameMatch) {
                string nameToCheck=llList2String(targetNames, 0);
                if(llGetSubString(nameToCheck, -1, -1)=="*") {
                    nameToCheck=llDeleteSubString(nameToCheck, -1, -1);
                    if(!llSubStringIndex(myName, nameToCheck)) {
                        nameMatch=TRUE;
                    }
                }
                else {
                    if(myName==nameToCheck) {
                        nameMatch=TRUE;
                    }
                }
                targetNames=llDeleteSubList(targetNames, 0, 0);
            }
        }
        
        if(nameMatch && groupMatch) {
            llDie();
        }
    }
    // begin old stuff
    else if(cmd=="die") {
        if(!MyGroup) {
            llDie();
        }
    }
    else if(cmd==llGetObjectName()+"=die") {
        if(MyGroup==1) {
            llDie();
        }
    }
    //end old stuff
}

default{
    //any script inside a prop can link message into this prop plugin and have it relay messages to the nPose system.
    //the core is expecting specificly a string like this:  "PROPRELAY|arbNum|message|toucherKey"
    //this prop script doesn't care what num is, it will be looking for the first 9 characters in the str to be "PROPRELAY"
    //we need to provide the other info that the core is looking for to process messages.
    link_message(integer sender, integer num, string str, key id){
        if (llGetSubString(str,0,8) == "PROPRELAY"){
            llRegionSayTo(Parent, ChatChannel, str);
        }
        
    }
    
    on_rez(integer param){
        //param contains the ChatChannel (the upper 3 bytes) and 1 byte (the lower) of additional data
        //DataBits:
        // 0: unused
        // 1: QuiteMode
        // 2,3,4,5,6,7 groupNumber
        Parent = NULL_KEY;
        if (param){
            MyPos = llGetPos();
            MyRot = llGetRot();
            
            ChatChannel = ((param >> 8) & 0x00FFFFFF) + 0x7F000000;
            QuietMode = (param >> 1) & 0x1;
            MyGroup = (param >> 2) & 0x2F;
            
            Lifetime = timeToLive();
            llListen(ChatChannel, "", "", "");
            llSetTimerEvent(TICKER_TIME);
            llRegionSay(ChatChannel, "ping");
        }else{
            llSetTimerEvent(0.0);
        }
    }

    listen(integer channel, string name, key id, string message){
        if(llGetOwnerKey(id) == llGetOwner()) {
            //check if the message is in JSON format (JSON Format should be used always)
            if(llJsonValueType(message, [])==JSON_ARRAY) {
                list commandLines=llJson2List(message);
                while(llGetListLength(commandLines)) {
                    list commandParts=llJson2List(llList2String(commandLines, 0));
                    execute(commandParts, id);
                    commandLines=llDeleteSubList(commandLines, 0, 0);
                }
            }
            else {
                //this is the old message format, don't use it anymore
                list msg = llParseString2List(message, ["|"], []);
                execute(msg, id);
            }
        }
    }

    timer(){
        if(Parent!=NULL_KEY) {
            //check if the parent still exists
            if(llKey2Name(Parent)=="") {
                //parent doesn't exist any more
                llDie();
            }
            //check if we provided a timeout in the prop prim description
            if(Lifetime>0.0) {
                Lifetime-=TICKER_TIME;
                if(Lifetime<=0.0) {
                    llDie();
                }
            }
        }
        
        if(!QuietMode) {
            integer doReport;
            if (llGetPos() != MyPos){
                MyPos = llGetPos();
                doReport = TRUE;
            }
            if (llGetRot() != MyRot){
                MyRot = llGetRot();
                doReport = TRUE;
            }
            if (doReport){
                report();
            }
        }
    }
}
