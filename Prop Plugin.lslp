/*
The nPose scripts are licensed under the GPLv2 (http://www.gnu.org/licenses/gpl-2.0.txt), with the following addendum:

The nPose scripts are free to be copied, modified, and redistributed, subject to the following conditions:
	- If you distribute the nPose scripts, you must leave them full perms.
	- If you modify the nPose scripts and distribute the modifications, you must also make your modifications full perms.

"Full perms" means having the modify, copy, and transfer permissions enabled in Second Life and/or other virtual world platforms derived from Second Life (such as OpenSim).  If the platform should allow more fine-grained permissions, then "full perms" will mean the most permissive possible set of permissions allowed by the platform.
*/
// This script has been optimized to run without running out of memory and is most likely unreadable code.

integer UThreadStackFrame = -240;
integer O = 310;
integer IsRestoring = 200;
integer UThread = -242;
integer edefaultexperience_permissions_denied;
integer gA;
integer gD;
integer edefaultlink_message;
integer edefaultexperience_permissions;
key ResumeVoid;
integer edefaultchanged;
integer LslUserScript;
integer gG = 1;
integer edefaultrez;
string System;
integer S;
integer edefaultattach;
integer Q;
vector edefaultstate_entry = <0, 0, 0>;
rotation gF = <0, 0, 0, 1>;
integer N;
integer Pop;
integer gC;
list edefaultrun_time_perms;
list R;
integer gL;
integer gB;
list gE;
list T;
key Library;
integer gK;
float IsSaveDue = 0;
float P = 0;
integer gJ;
integer g_;
vector edefaulttimer = <0, 0, 0>;
integer LslLibrary = 1;
vector edefaultchat = <0, 0, 0>;
integer gH = 1;
list M = 
    [ "PLUGINCOMMAND"
    , O
    , 0
    , "DEFAULTCARD"
    , UThread
    , 0
    , "OPTION"
    , UThreadStackFrame
    , 0
    , "OPTIONS"
    , UThreadStackFrame
    , 0
    , "DOCARD"
    , IsRestoring
    , 0
    , "TIMER"
    , -600
    , 1
    , "TIMER_REMOVE"
    , -601
    , 0
    ];
list gI;

F()
{
    if (-(llGetPermissionsKey() == Library) & (llGetPermissions() & 32))
    {
        if (~gK)
        {
            if (g_)
            {
                llAttachToAvatarTemp(gK);
            }
            else
            {
                llAttachToAvatar(gK);
            }
            gC = 0;
        }
        else
        {
            llDetachFromAvatar();
        }
        Library = "00000000-0000-0000-0000-000000000000";
        gK = 0;
        IsSaveDue = 0;
        P = llGetTime() + -P;
    }
}

L(string llGetObjectDetails)
{
    if (edefaultlink_message)
    {
        llRegionSayTo(ResumeVoid, gA, llGetObjectDetails);
    }
}

K(key llGetObjectDetails, string llGetObjectPermMask)
{
    if (edefaultexperience_permissions)
    {
        if (llGetObjectDetails)
        {
            llRegionSayTo(llGetObjectDetails, gD, llGetObjectPermMask);
        }
        else
        {
            llRegionSay(gD, llGetObjectPermMask);
        }
    }
}

string I(vector llGetObjectPermMask, integer llGetObjectDetails)
{
    return "<" + E(llGetObjectPermMask.x, llGetObjectDetails) + ", " + E(llGetObjectPermMask.y, llGetObjectDetails) + ", " + E(llGetObjectPermMask.z, llGetObjectDetails) + ">";
}

string E(float llGetObjectPermMask, integer llGetObjectDetails)
{
    string loc_valueString = (string)((float)llRound(llGetObjectPermMask * llPow(10, llGetObjectDetails)) / llPow(10, llGetObjectDetails));
    string loc_char;
    do
    {
        loc_char = llGetSubString(loc_valueString, ((integer)-1), ((integer)-1));
        if (loc_char == "." | loc_char == "0")
        {
            loc_valueString = llDeleteSubString(loc_valueString, ((integer)-1), ((integer)-1));
        }
    }
    while (loc_char == "0");
    return loc_valueString;
}

list C()
{
    if (ResumeVoid)
    {
        list loc_temp = llGetObjectDetails(ResumeVoid, (list)3 + 4 + 18);
        if (!gH)
        {
            return (list)llList2Vector(loc_temp, 0) + llList2Rot(loc_temp, 1);
        }
        loc_temp = llGetObjectDetails(llList2Key(loc_temp, 2), (list)3 + 4);
        return (list)llList2Vector(loc_temp, 0) + llList2Rot(loc_temp, 1);
    }
    return (list)<((float)0), ((float)0), ((float)0)> + <((float)0), ((float)0), ((float)0), ((float)1)>;
}

B()
{
    if (ResumeVoid)
    {
        list loc_temp = C();
        vector loc_parentPos = llList2Vector(loc_temp, 0);
        rotation loc_parentRot = llList2Rot(loc_temp, 1);
        string loc_rootName = (string)llGetLinkPrimitiveParams(1 < llGetNumberOfPrims(), (list)27);
        vector loc_reportingPos = <((float)0), ((float)0), ((float)0)>;
        rotation loc_reportingRot = <((float)0), ((float)0), ((float)0), ((float)1)>;
        loc_reportingPos = (edefaultstate_entry - loc_parentPos) / loc_parentRot;
        loc_reportingRot = gF / loc_parentRot;
        if (edefaultattach)
        {
            if (!(edefaultchat.x == ((float)0) | edefaultchat.y == ((float)0) | edefaultchat.z == ((float)0)))
            {
                loc_reportingPos = <loc_reportingPos.x / edefaultchat.x, loc_reportingPos.y / edefaultchat.y, loc_reportingPos.z / edefaultchat.z>;
            }
        }
        loc_temp = [];
        if (edefaultchanged)
        {
            loc_temp = loc_temp + "quiet";
        }
        if (gG)
        {
            loc_temp = loc_temp + "nPose";
        }
        if (LslUserScript)
        {
            loc_temp = loc_temp + "noParentCheck";
        }
        if (edefaultattach)
        {
            loc_temp = loc_temp + "scalePos";
        }
        if (Q)
        {
            loc_temp = loc_temp + "scaleSize";
        }
        string loc_flags = llList2CSV(loc_temp);
        list loc_parts = ["PROP", loc_rootName, I(loc_reportingPos, 3), I(llRot2Euler(loc_reportingRot) * 57.29578, 2)];
        if (System == "")
            if (loc_flags == "")
            {
                if (edefaultrez)
                {
                    loc_parts = loc_parts + (string)edefaultrez;
                }
            }
            else
            {
                loc_parts = loc_parts + (string)edefaultrez + loc_flags;
            }
        else
        {
            loc_parts = loc_parts + (string)edefaultrez + loc_flags + System;
        }
        llRegionSayTo(llGetOwner(), 0, llDumpList2String(loc_parts, "|"));
    }
}

string H(string llGetObjectDetails, list llGetObjectPermMask)
{
    if (llGetObjectDetails == "")
    {
        return llList2Json("﷒", (list)llList2Json("﷒", llGetObjectPermMask));
    }
    else
    {
        return llList2Json("﷒", llJson2List(llGetObjectDetails) + llList2Json("﷒", llGetObjectPermMask));
    }
}

A()
{
    integer loc_break;
    if (edefaultrun_time_perms != [])
    {
        float loc_now = llGetTime();
        while (!(edefaultrun_time_perms == [] | loc_break))
        {
            if (llList2Float(edefaultrun_time_perms, 1) < loc_now)
            {
                edefaultrun_time_perms = llDeleteSubList(edefaultrun_time_perms, 0, 5);
            }
            else
            {
                loc_break = 1;
            }
        }
    }
    loc_break = 0;
    if (R != [])
    {
        float loc_now = llGetTime();
        while (!(R == [] | loc_break))
        {
            if (llList2Float(R, 1) < loc_now)
            {
                R = llDeleteSubList(R, 0, 1);
            }
            else if (~llGetInventoryType(llList2String(R, 0)))
            {
                R = llDeleteSubList(R, 0, 1);
            }
            else
            {
                loc_break = 1;
            }
        }
    }
    if (-(R == []) & gL)
    {
        gL = 0;
        llAllowInventoryDrop(0);
    }
    loc_break = 0;
    while (!(gE == [] | loc_break))
    {
        string loc_commandString = llList2String(gE, 0);
        list loc_commandParts = llParseStringKeepNulls(loc_commandString, (list)"|", []);
        key loc_id = llList2Key(gE, 1);
        string loc_cmd = llList2String(loc_commandParts, 0);
        if (loc_cmd == "COPY")
        {
            gE = llDeleteSubList(gE, 0, 1);
            if (edefaultlink_message)
            {
                if (llGetObjectPermMask(1) & 16384)
                {
                    float loc_timeout = 1 + llGetTime();
                    list loc_items = llCSV2List(llList2String(loc_commandParts, 1));
                    list loc_itemsToCopy;
                    while (loc_items != [])
                    {
                        string loc_item = llList2String(loc_items, 0);
                        loc_items = llDeleteSubList(loc_items, 0, 0);
                        if (!~llGetInventoryType(loc_item))
                        {
                            loc_itemsToCopy = loc_itemsToCopy + loc_item;
                            R = R + loc_item + loc_timeout;
                        }
                    }
                    if (loc_itemsToCopy != [])
                    {
                        L(H("", "CONTROL_COPY" + loc_itemsToCopy + loc_id));
                        if (!(llGetOwnerKey(ResumeVoid) == llGetOwner() | gL))
                        {
                            gL = 1;
                            llAllowInventoryDrop(1);
                        }
                    }
                }
            }
        }
        else if (loc_cmd == "PROP")
        {
            if (R != [])
            {
                loc_break = 1;
            }
            else
            {
                gE = llDeleteSubList(gE, 0, 1);
                if (!edefaultexperience_permissions)
                {
                    edefaultexperience_permissions = llListen(gD, "", "", "");
                }
                string loc_propName = llList2String(loc_commandParts, 1);
                list loc_objects;
                if (llGetSubString(loc_propName, ((integer)-1), ((integer)-1)) == "*")
                {
                    loc_propName = llDeleteSubString(loc_propName, ((integer)-1), ((integer)-1));
                    integer loc_length = llGetInventoryNumber(6);
                    integer loc_index;
                    for (loc_index = 0; loc_index < loc_length; ++loc_index)
                    {
                        string loc_inventoryName = llGetInventoryName(6, loc_index);
                        if (!llSubStringIndex(loc_inventoryName, loc_propName))
                        {
                            loc_objects = loc_objects + loc_inventoryName;
                        }
                    }
                }
                else if (llGetInventoryType(loc_propName) == 6)
                {
                    loc_objects = (list)loc_propName;
                }
                if (loc_objects != [])
                {
                    integer loc_propGroup = (integer)llList2String(loc_commandParts, 4);
                    list loc_propFlags = llCSV2List(llToLower(llList2String(loc_commandParts, 5)));
                    string loc_propNamespace = llStringTrim(llList2String(loc_commandParts, 6), 3);
                    integer loc_scalePosMode = !!~llListFindList(loc_propFlags, (list)"scalepos");
                    integer loc_scaleSizeMode = !!~llListFindList(loc_propFlags, (list)"scalesize");
                    vector loc_ncPos = (vector)llList2String(loc_commandParts, 2);
                    vector loc_scaledNcPos = loc_ncPos;
                    rotation loc_ncRot = llEuler2Rot((vector)llList2String(loc_commandParts, 3) * 0.017453292);
                    vector loc_scalingFactor = <((float)1), ((float)1), ((float)1)>;
                    if (loc_scalePosMode | loc_scaleSizeMode)
                    {
                        if (edefaultlink_message)
                        {
                            if (!(edefaultchat.x == ((float)0) | edefaultchat.y == ((float)0) | edefaultchat.z == ((float)0)))
                            {
                                loc_scalingFactor = edefaultchat;
                            }
                        }
                        else
                        {
                            if (!(edefaulttimer.x == ((float)0) | edefaulttimer.y == ((float)0) | edefaulttimer.z == ((float)0)))
                            {
                                vector loc_rootScale = llList2Vector(llGetLinkPrimitiveParams(1 < llGetNumberOfPrims(), (list)7), 0);
                                loc_scalingFactor = <loc_rootScale.x / edefaulttimer.x, loc_rootScale.y / edefaulttimer.y, loc_rootScale.z / edefaulttimer.z>;
                            }
                        }
                    }
                    if (loc_scalePosMode)
                    {
                        if (LslLibrary)
                        {
                            loc_scaledNcPos = <loc_ncPos.x * loc_scalingFactor.x, loc_ncPos.y * loc_scalingFactor.y, loc_ncPos.z * loc_scalingFactor.z>;
                        }
                        else
                        {
                            loc_scaledNcPos = loc_scaledNcPos * llGetLocalRot();
                            loc_scaledNcPos = <loc_ncPos.x * loc_scalingFactor.x, loc_ncPos.y * loc_scalingFactor.y, loc_ncPos.z * loc_scalingFactor.z>;
                            loc_scaledNcPos = loc_scaledNcPos / llGetLocalRot();
                        }
                    }
                    rotation loc_propRezRot = <((float)0), ((float)0), ((float)0), ((float)1)>;
                    vector loc_propRezPos = <((float)0), ((float)0), ((float)0)>;
                    if (LslLibrary)
                    {
                        loc_propRezRot = loc_ncRot * llGetRootRotation();
                        loc_propRezPos = llGetRootPosition() + loc_scaledNcPos * llGetRootRotation();
                    }
                    else
                    {
                        loc_propRezRot = loc_ncRot * llGetRot();
                        loc_propRezPos = llGetPos() + loc_scaledNcPos * llGetRot();
                    }
                    vector loc_propMovePos = <((float)0), ((float)0), ((float)0)>;
                    if (!(llVecDist(llGetPos(), loc_propRezPos) < ((float)10)))
                    {
                        loc_propMovePos = loc_propRezPos;
                        loc_propRezPos = llGetPos();
                    }
                    while (loc_objects != [])
                    {
                        loc_propName = llList2String(loc_objects, 0);
                        loc_objects = llDeleteSubList(loc_objects, 0, 0);
                        ++gB;
                        if (255 < gB)
                        {
                            gB = 1;
                        }
                        integer loc_rezParam = (gB & 255) * 16777216 | (loc_propGroup & 255) * 65536;
                        llRezAtRoot(loc_propName, loc_propRezPos, <((float)0), ((float)0), ((float)0)>, loc_propRezRot, loc_rezParam);
                        edefaultrun_time_perms = edefaultrun_time_perms + gB + (((float)3) + llGetTime()) + llList2CSV(loc_propFlags) + loc_scalingFactor + loc_propMovePos + loc_propNamespace;
                    }
                }
            }
        }
        else if (edefaultrun_time_perms == [] & R == [])
        {
            gE = llDeleteSubList(gE, 0, 1);
            K("00000000-0000-0000-0000-000000000000", H("", loc_commandParts + loc_id));
        }
        else
        {
            loc_break = 1;
        }
    }
}

D()
{
    if (llGetAttached())
    {
        Library = llGetOwner();
        gK = ((integer)-1);
        IsSaveDue = 0;
        P = 0;
        llRequestPermissions(Library, 32);
    }
    else
    {
        L(H("", (list)"CONTROL_PROP_DIED" + llGetKey()));
        llDie();
    }
}

integer J(string llGetObjectPermMask, string llGetTime, string llGetObjectDetails)
{
    if (!(llGetObjectDetails == System))
    {
        return 0;
    }
    string loc_rootName = llGetLinkName(1 < llGetNumberOfPrims());
    integer loc_nameMatch = !!(llGetObjectPermMask == "" | llGetObjectPermMask == "*");
    integer loc_groupMatch = !!(llGetTime == "" | llGetTime == "*");
    if (!loc_groupMatch)
    {
        list loc_targetGroups = llCSV2List(llGetTime);
        if (~llListFindList(loc_targetGroups, (list)((string)edefaultrez)))
        {
            loc_groupMatch = 1;
        }
    }
    if (loc_groupMatch & -!loc_nameMatch)
    {
        list loc_targetNames = llCSV2List(llGetObjectPermMask);
        while (!(loc_targetNames == [] | loc_nameMatch))
        {
            string loc_nameToCheck = llList2String(loc_targetNames, 0);
            if (llGetSubString(loc_nameToCheck, ((integer)-1), ((integer)-1)) == "*")
            {
                loc_nameToCheck = llDeleteSubString(loc_nameToCheck, ((integer)-1), ((integer)-1));
                if (!llSubStringIndex(loc_rootName, loc_nameToCheck))
                {
                    loc_nameMatch = 1;
                }
            }
            else
            {
                if (loc_rootName == loc_nameToCheck)
                {
                    loc_nameMatch = 1;
                }
            }
            loc_targetNames = llDeleteSubList(loc_targetNames, 0, 0);
        }
    }
    return !(!loc_groupMatch | !loc_nameMatch);
}

_(integer llGetObjectDetails)
{
    gG = 1;
    ResumeVoid = "00000000-0000-0000-0000-000000000000";
    System = "";
    gA = 0;
    gD = (integer)("0x7F" + llGetSubString((string)llGetKey(), 0, 5));
    llListenRemove(edefaultlink_message);
    edefaultlink_message = 0;
    llListenRemove(edefaultexperience_permissions);
    edefaultexperience_permissions = 0;
    edefaultexperience_permissions_denied = 0;
    gC = 0;
    Pop = 0;
    llSetTimerEvent(((float)1));
    Library = "00000000-0000-0000-0000-000000000000";
    gK = 0;
    IsSaveDue = ((float)0);
    P = ((float)0);
    edefaultrun_time_perms = [];
    gE = [];
    N = 0;
    if (llGetObjectDetails)
    {
        gG = 0;
        ResumeVoid = (key)((string)llGetObjectDetails(llGetKey(), (list)32));
        gA = (integer)("0x7F" + llGetSubString((string)ResumeVoid, 0, 5));
        edefaultlink_message = llListen(gA, "", ResumeVoid, "");
        S = llGetObjectDetails >> 24 & 255;
        edefaultrez = llGetObjectDetails >> 16 & 255;
        Pop = 1;
        L(H("", (list)"CONTROL_PROP_REZZED" + S + llGetKey()));
        edefaultstate_entry = llGetRootPosition();
        gF = llGetRootRotation();
    }
}

G(list llGetObjectPermMask, key llGetObjectDetails)
{
    string loc_cmd = llList2String(llGetObjectPermMask, 0);
    if (loc_cmd == "PROP_DO" | loc_cmd == "PROP_DO_ALL" | loc_cmd == "PROP" | loc_cmd == "COPY")
    {
        gE = gE + llDumpList2String(llGetObjectPermMask, "|") + llGetObjectDetails;
        A();
    }
    else if (loc_cmd == "PARENT_DO" | loc_cmd == "PARENT_DO_ALL")
    {
        L(H("", llGetObjectPermMask + llGetObjectDetails));
    }
    else if (loc_cmd == "DIE")
    {
        D();
    }
    else if (loc_cmd == "POS")
    {
        vector loc_newPos = (vector)llList2String(llGetObjectPermMask, 1);
        if (edefaultattach)
        {
            if (!(edefaultchat.x == ((float)0) | edefaultchat.y == ((float)0) | edefaultchat.z == ((float)0)))
            {
                loc_newPos = <loc_newPos.x * edefaultchat.x, loc_newPos.y * edefaultchat.y, loc_newPos.z * edefaultchat.z>;
            }
        }
        llSetRegionPos(llList2Vector(C(), 0) + loc_newPos);
    }
    else if (loc_cmd == "ROT")
    {
        llSetLinkPrimitiveParamsFast(1, [8, llList2Rot(C(), 1) * (rotation)llList2String(llGetObjectPermMask, 1)]);
    }
    else if (loc_cmd == "ATTACH" | loc_cmd == "TEMPATTACH")
    {
        if (!llGetAttached())
        {
            g_ = loc_cmd == "TEMPATTACH";
            key loc_avatarUuid = (key)llList2String(llGetObjectPermMask, 1);
            if (loc_avatarUuid)
            {
                integer loc_objectPerms = llGetObjectPermMask(1);
                if (loc_objectPerms & 8192)
                {
                    Library = loc_avatarUuid;
                    gK = (integer)llList2String(llGetObjectPermMask, 2);
                    gJ = (integer)llList2String(llGetObjectPermMask, 3);
                    if (!(Library == llGetOwner()))
                    {
                        if (~-gJ)
                        {
                            if (gJ == 2)
                            {
                                L(H("", (list)"CONTROL_ADD_TO_WHITELIST" + llGetKey()));
                            }
                        }
                        else
                        {
                            loc_objectPerms = llGetObjectPermMask(4);
                            if (!(loc_objectPerms & 16384))
                            {
                                L(H("", (list)"CONTROL_ADD_TO_WHITELIST" + llGetKey()));
                            }
                        }
                    }
                    IsSaveDue = ((float)60);
                    if (!(llStringTrim(llList2String(llGetObjectPermMask, 4), 3) == ""))
                    {
                        IsSaveDue = (float)llList2String(llGetObjectPermMask, 4);
                    }
                    IsSaveDue = IsSaveDue + llGetTime();
                    P = ((float)3);
                    if (!(llStringTrim(llList2String(llGetObjectPermMask, 5), 3) == ""))
                    {
                        P = (float)llList2String(llGetObjectPermMask, 5);
                    }
                    P = -P;
                    list loc_expDetails = llGetExperienceDetails("");
                    if (loc_expDetails == [] | llList2Integer(loc_expDetails, 3))
                    {
                        llRequestPermissions(Library, 32);
                    }
                    else
                    {
                        llRequestExperiencePermissions(Library, "");
                    }
                }
            }
        }
    }
    else if (!(loc_cmd == "LINKMSG") | gG)
        if (gG)
        {
            llMessageLinked(((integer)-1), 220, llDumpList2String(llGetObjectPermMask, "|"), llGetObjectDetails);
        }
        else
        {
            integer loc_index = llListFindList(gI + M, (list)loc_cmd);
            if (~loc_index)
            {
                integer loc_num = llList2Integer(gI + M, -~loc_index);
                string loc_str = llDumpList2String(llDeleteSubList(llGetObjectPermMask, 0, 0), "|");
                llMessageLinked(((integer)-1), loc_num, loc_str, llGetObjectDetails);
            }
            else
            {
                llMessageLinked(((integer)-1), 220, llDumpList2String(llGetObjectPermMask, "|"), llGetObjectDetails);
            }
        }
    else
    {
        llMessageLinked(((integer)-1), (integer)llList2String(llGetObjectPermMask, 1), llList2String(llGetObjectPermMask, 2), (key)llList2String(llGetObjectPermMask, 3));
    }
}

default
{
    state_entry()
    {
        _(0);
    }

    link_message(integer llGetObjectPermMask, integer llGetObjectDetails, string llGetTime, key llGetOwnerKey)
    {
        if (llGetObjectDetails ^ ((integer)-500))
            if (llGetObjectDetails ^ 204)
                if (llGetObjectDetails == O | llGetObjectDetails == 309)
                {
                    if (!~llSubStringIndex(llGetTime, ","))
                    {
                        llGetTime = llList2CSV(llDeleteSubList(llParseStringKeepNulls(llGetTime, (list)"|", []), 2, 2));
                    }
                    list loc_parts = llParseString2List(llGetTime, (list)"|", []);
                    while (loc_parts != [])
                    {
                        list loc_subParts = llCSV2List(llList2String(loc_parts, 0));
                        loc_parts = llDeleteSubList(loc_parts, 0, 0);
                        string loc_action = llList2String(loc_subParts, 0);
                        integer loc_index = llListFindList(gI, (list)loc_action);
                        if (-(llGetObjectDetails == O) & ~loc_index)
                        {
                            gI = llDeleteSubList(gI, loc_index, ~-(3 + loc_index));
                        }
                        if (!(-!(llGetObjectDetails == O) & ~loc_index))
                        {
                            gI = gI + loc_action + (integer)llList2String(loc_subParts, 1) + (integer)llList2String(loc_subParts, 2);
                        }
                    }
                }
                else if (llGetObjectDetails ^ UThreadStackFrame)
                {
                    if (llGetObjectDetails == 34334)
                    {
                        llSay(0, "Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit() + ", Leaving " + (string)llGetFreeMemory() + " memory free.");
                    }
                }
                else
                {
                    list loc_optionsToSet = llParseStringKeepNulls(llGetTime, (list)"~" + "|", []);
                    integer loc_length = loc_optionsToSet != [];
                    integer loc_index;
                    for (loc_index = 0; loc_index < loc_length; ++loc_index)
                    {
                        list loc_optionsItems = llParseString2List(llList2String(loc_optionsToSet, loc_index), (list)"=", []);
                        string loc_optionItem = llToLower(llStringTrim(llList2String(loc_optionsItems, 0), 3));
                        string loc_optionString = llList2String(loc_optionsItems, 1);
                        string loc_optionSetting = llToLower(llStringTrim(loc_optionString, 3));
                        integer loc_optionSettingFlag = !!(loc_optionSetting == "on" | (integer)loc_optionSetting);
                        if (loc_optionItem == "scaleref")
                        {
                            edefaulttimer = (vector)loc_optionString;
                        }
                        else if (loc_optionItem == "proprefroot")
                        {
                            LslLibrary = loc_optionSettingFlag;
                        }
                    }
                }
            else
            {
                gE = gE + "CONTROL_DUMP" + llGetOwnerKey;
                A();
            }
        else
        {
            list loc_commandLines = llParseString2List(llGetTime, (list)"%&§", []);
            while (loc_commandLines != [])
            {
                list loc_commandParts = llParseStringKeepNulls(llList2String(loc_commandLines, 0), (list)"|", []);
                loc_commandLines = llDeleteSubList(loc_commandLines, 0, 0);
                G(loc_commandParts, llGetOwnerKey);
            }
        }
    }

    run_time_permissions(integer llGetObjectDetails)
    {
        F();
    }

    experience_permissions(key llGetObjectDetails)
    {
        F();
    }

    experience_permissions_denied(key llGetObjectPermMask, integer llGetObjectDetails)
    {
        if (llGetObjectPermMask == Library)
        {
            llRequestPermissions(Library, 32);
        }
    }

    attach(key llGetObjectDetails)
    {
        if (llGetObjectDetails)
        {
            P = ((float)0);
            L(H("", (list)"CONTROL_PROP_ATTACHED" + (string)llGetLinkPrimitiveParams(1 < llGetNumberOfPrims(), (list)27) + edefaultrez + llGetKey()));
        }
        else
        {
            L(H("", (list)"CONTROL_PROP_DETACHED" + (string)llGetLinkPrimitiveParams(1 < llGetNumberOfPrims(), (list)27) + edefaultrez + llGetKey()));
        }
    }

    listen(integer llGetTime, string llGetObjectPermMask, key llGetOwnerKey, string llGetObjectDetails)
    {
        if (!(llGetOwnerKey(llGetOwnerKey) == llGetOwner()))
        {
            if (!(llGetOwnerKey == ResumeVoid))
            {
                if (!~llListFindList(T, (list)llGetOwnerKey))
                {
                    return;
                }
            }
        }
        if (!(llJsonValueType(llGetObjectDetails, []) == "﷒"))
        {
            return;
        }
        list loc_commandLines = llJson2List(llGetObjectDetails);
        while (loc_commandLines != [])
        {
            list loc_commandParts = llJson2List(llList2String(loc_commandLines, 0));
            loc_commandLines = llDeleteSubList(loc_commandLines, 0, 0);
            string loc_cmd = llList2String(loc_commandParts, 0);
            key loc_keyPart = (key)llList2String(loc_commandParts, ((integer)-1));
            loc_commandParts = llDeleteSubList(loc_commandParts, ((integer)-1), ((integer)-1));
            if (llGetTime ^ gA)
            {
                if (llGetTime == gD)
                {
                    if (loc_cmd == "CONTROL_PROP_REZZED")
                    {
                        integer loc_propId = (integer)llList2String(loc_commandParts, 1);
                        integer loc_index = llListFindList(edefaultrun_time_perms, (list)loc_propId);
                        if (~loc_index)
                        {
                            string loc_childCommands;
                            vector loc_newPos = llList2Vector(edefaultrun_time_perms, 4 + loc_index);
                            if (!(loc_newPos == <((float)0), ((float)0), ((float)0)>))
                            {
                                loc_childCommands = H("", (list)"CONTROL_SET_POS_GLOBAL" + loc_newPos + "");
                            }
                            loc_childCommands = H(loc_childCommands, (list)"CONTROL_SET_FLAGS" + llList2String(edefaultrun_time_perms, -~-~loc_index) + "");
                            loc_childCommands = H(loc_childCommands, (list)"CONTROL_SET_OTHER" + LslLibrary + llList2Vector(edefaultrun_time_perms, 3 + loc_index) + llList2String(edefaultrun_time_perms, 5 + loc_index) + "");
                            K(llGetOwnerKey, loc_childCommands);
                            loc_childCommands = H("", "CONTROL_SET_PLUGIN_COMMANDS" + gI + "");
                            K(llGetOwnerKey, loc_childCommands);
                        }
                    }
                    else if (loc_cmd == "CONTROL_SETUP_FINISHED")
                    {
                        integer loc_propId = (integer)llList2String(loc_commandParts, 1);
                        integer loc_index = llListFindList(edefaultrun_time_perms, (list)loc_propId);
                        if (~loc_index)
                        {
                            edefaultrun_time_perms = llDeleteSubList(edefaultrun_time_perms, loc_index, ~-(6 + loc_index));
                        }
                        llMessageLinked(((integer)-1), ((integer)-790), llDumpList2String((list)llGetObjectPermMask + llGetOwnerKey + llGetTime + llDeleteSubList(loc_commandParts, 0, 0), "|"), "00000000-0000-0000-0000-000000000000");
                        A();
                    }
                    else if (loc_cmd == "CONTROL_PROP_DIED")
                    {
                        integer loc_index = llListFindList(T, (list)llGetOwnerKey);
                        if (~loc_index)
                        {
                            T = llDeleteSubList(T, loc_index, loc_index);
                        }
                    }
                    else if (loc_cmd == "CONTROL_ADD_TO_WHITELIST")
                    {
                        integer loc_index = llListFindList(T, (list)llGetOwnerKey);
                        if (!~loc_index)
                        {
                            T = T + llGetOwnerKey;
                        }
                    }
                    else if (loc_cmd == "CONTROL_COPY")
                    {
                        if (llGetOwnerKey(llGetOwnerKey) == llGetOwner())
                        {
                            list loc_items = llDeleteSubList(loc_commandParts, 0, 0);
                            while (loc_items != [])
                            {
                                string loc_item = llList2String(loc_items, 0);
                                loc_items = llDeleteSubList(loc_items, 0, 0);
                                if (~llGetInventoryType(loc_item) & -!(llGetInventoryType(loc_item) == 10))
                                {
                                    integer loc_perm = llGetInventoryPermMask(loc_item, 1);
                                    if (loc_perm & 32768)
                                    {
                                        llGiveInventory(llGetOwnerKey, loc_item);
                                    }
                                }
                            }
                        }
                    }
                    else if (loc_cmd == "PARENT_DO_ALL")
                    {
                        G(loc_commandParts, loc_keyPart);
                        G(llDeleteSubList(loc_commandParts, 0, 0), loc_keyPart);
                    }
                    else if (loc_cmd == "PARENT_DO")
                    {
                        G(llDeleteSubList(loc_commandParts, 0, 0), loc_keyPart);
                    }
                }
            }
            else
            {
                if (loc_cmd == "CONTROL_SET_POS_GLOBAL")
                {
                    llSetRegionPos((vector)llList2String(loc_commandParts, 1));
                    gF = llGetRootRotation();
                    edefaultstate_entry = llGetRootPosition();
                }
                else if (loc_cmd == "CONTROL_SET_FLAGS")
                {
                    list loc_myFlags = llCSV2List(llToLower(llList2String(loc_commandParts, 1)));
                    edefaultchanged = !!~llListFindList(loc_myFlags, (list)"quiet");
                    gG = !!~llListFindList(loc_myFlags, (list)"npose");
                    LslUserScript = !!~llListFindList(loc_myFlags, (list)"noparentcheck");
                    edefaultattach = !!~llListFindList(loc_myFlags, (list)"scalepos");
                    Q = !!~llListFindList(loc_myFlags, (list)"scalesize");
                    gC = !edefaultchanged;
                    Pop = !LslUserScript;
                }
                else if (loc_cmd == "CONTROL_SET_OTHER")
                {
                    N = N | 1;
                    gH = (integer)llList2String(loc_commandParts, 1);
                    edefaultchat = (vector)llList2String(loc_commandParts, 2);
                    System = llList2String(loc_commandParts, 3);
                    if (Q)
                    {
                        if (!(edefaultchat.x == ((float)1) & edefaultchat.y == ((float)1) & edefaultchat.z == ((float)1)))
                        {
                            integer loc_count = llGetObjectPrimCount(llGetKey());
                            if (!loc_count)
                            {
                                loc_count = llGetNumberOfPrims();
                            }
                            vector loc_rootSize = llList2Vector(llGetLinkPrimitiveParams(1 < loc_count, (list)7), 0);
                            llSetLinkPrimitiveParamsFast(1 < loc_count, (list)7 + <loc_rootSize.x * edefaultchat.x, loc_rootSize.y * edefaultchat.y, loc_rootSize.z * edefaultchat.z>);
                            integer loc_index;
                            for (loc_index = 2; !(loc_count < loc_index); ++loc_index)
                            {
                                list loc_temp = llGetLinkPrimitiveParams(loc_index, (list)33 + 7);
                                vector loc_localPos = llList2Vector(loc_temp, 0);
                                vector loc_localSize = llList2Vector(loc_temp, 1);
                                llSetLinkPrimitiveParamsFast(loc_index, (list)33 + <loc_localPos.x * edefaultchat.x, loc_localPos.y * edefaultchat.y, loc_localPos.z * edefaultchat.z> + 7 + <loc_localSize.x * edefaultchat.x, loc_localSize.y * edefaultchat.y, loc_localSize.z * edefaultchat.z>);
                            }
                        }
                    }
                    if (N == 3)
                    {
                        L(H("", (list)"CONTROL_SETUP_FINISHED" + S + edefaultrez + ""));
                    }
                }
                else if (loc_cmd == "CONTROL_SET_PLUGIN_COMMANDS")
                {
                    N = N | 2;
                    loc_commandParts = llDeleteSubList(loc_commandParts, 0, 0);
                    integer loc_index;
                    integer loc_length = loc_commandParts != [];
                    list loc_tempList;
                    for (loc_index = 0; loc_index < loc_length; loc_index = 3 + loc_index)
                    {
                        loc_tempList = loc_tempList + llList2CSV(llList2List(loc_commandParts, loc_index, ~-(3 + loc_index)));
                    }
                    llMessageLinked(((integer)-1), 309, llDumpList2String(loc_tempList, "|"), loc_keyPart);
                    if (N == 3)
                    {
                        L(H("", (list)"CONTROL_SETUP_FINISHED" + S + edefaultrez + ""));
                    }
                }
                else if (loc_cmd == "CONTROL_DUMP")
                {
                    if (System == "")
                    {
                        B();
                    }
                }
                else if (loc_cmd == "PROP_DO" | loc_cmd == "PROP_DO_ALL")
                {
                    if (loc_cmd == "PROP_DO_ALL")
                    {
                        G(loc_commandParts, loc_keyPart);
                    }
                    if (J(llList2String(loc_commandParts, 1), llList2String(loc_commandParts, 2), llList2String(loc_commandParts, 3)))
                    {
                        G(llDeleteSubList(loc_commandParts, 0, 3), loc_keyPart);
                    }
                }
            }
        }
    }

    on_rez(integer llGetObjectDetails)
    {
        _(llGetObjectDetails);
    }

    changed(integer llGetObjectDetails)
    {
        if (llGetObjectDetails & 1)
        {
            if (R != [])
            {
                A();
            }
        }
    }

    timer()
    {
        ++edefaultexperience_permissions_denied;
        A();
        if (!(edefaultexperience_permissions_denied % 10))
        {
            if (gC)
            {
                if (!(edefaultstate_entry == llGetRootPosition() & gF == llGetRootRotation()))
                {
                    edefaultstate_entry = llGetRootPosition();
                    gF = llGetRootRotation();
                    B();
                }
            }
            if (Pop)
            {
                if (llKey2Name(ResumeVoid) == "")
                {
                    D();
                }
            }
            if (((float)0) < IsSaveDue)
            {
                if (IsSaveDue < llGetTime())
                {
                    D();
                }
            }
            if (((float)0) < P)
            {
                if (P < llGetTime())
                {
                    D();
                }
            }
        }
        if (!(edefaultexperience_permissions_denied % 180))
        {
            integer loc_index;
            integer loc_length = T != [];
            for (loc_index = 0; loc_index < loc_length; ++loc_index)
            {
                if (llKey2Name(llList2Key(T, loc_index)) == "")
                {
                    T = llDeleteSubList(T, loc_index, loc_index);
                    --loc_index;
                    --loc_length;
                }
            }
        }
    }
}
