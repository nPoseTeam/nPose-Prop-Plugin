/*
The nPose scripts are licensed under the GPLv2 (http://www.gnu.org/licenses/gpl-2.0.txt), with the following addendum:

The nPose scripts are free to be copied, modified, and redistributed, subject to the following conditions:
	- If you distribute the nPose scripts, you must leave them full perms.
	- If you modify the nPose scripts and distribute the modifications, you must also make your modifications full perms.

"Full perms" means having the modify, copy, and transfer permissions enabled in Second Life and/or other virtual world platforms derived from Second Life (such as OpenSim).  If the platform should allow more fine-grained permissions, then "full perms" will mean the most permissive possible set of permissions allowed by the platform.
*/
// This script has been optimized to run without running out of memory and is most likely unreadable code.

integer DUMP = 204;
integer DO=220;
integer OPTIONS=-240;
integer PLUGIN_COMMAND_REGISTER_NO_OVERWRITE=309;
integer PLUGIN_COMMAND_REGISTER=310;
integer PROP_PLUGIN=-500;
integer MEMORY_USAGE=34334;

integer DOPOSE=200;
integer DEFAULT_CARD=-242;
integer ON_PROP_REZZED=-790;

float TIMER_TIME=1.0;
integer SLOW_TIMER_FACTOR=10;
integer VERY_SLOW_TIMER_FACTOR=180;
float PROP_TIMEOUT=3.0;
float COPY_TIMEOUT=2.0;
float ATTACH_TIMEOUT=3.0;
float PERMISSION_TIMEOUT=60.0;
integer TimerCounter;

integer ParentChatChannel;
integer ChildChatChannel;
integer ParentListenerHandle;
integer ChildListenerHandle;

key MyParentId;
integer MyQuietMode;
integer MyNoParentCheckMode; //1: don't die with parent
//integer MyIgnoreGroupWildcardsMode; //1: don't die if wildcards are used
integer MyNPoseMode=1; //0: Try to decode the messages and send them directly; 1: use the nPose Core to decode them (which also means: Placeholders are inserted)
integer MyGroupNumber;
string MyNamespace;
integer MyPropId;
integer MyScalePosMode; //1: the position is scaled
integer MyScaleSizeMode; //1: the size should be scaled
vector MyRootPos;
rotation MyRootRot;
integer MySetupFinished; // bit0: CONTROL_SET_OPTIONS finished; bit1: CONTROL_SET_PLUGIN_COMMANDS finished

integer TimerFlagCheckParent; //this is a slow timer
integer TimerFlagCheckPosRot; //this is a slow timer

list RezzingPropList; // [integer propId, float timeout, string flags, vector scalingFactor, vector newGlobalPos, string namespace]
integer REZZING_PROP_ID=0;
integer REZZING_PROP_TIMEOUT=1;
integer REZZING_PROP_FLAGS=2;
integer REZZING_PROP_SCALING_FACTOR=3;
integer REZZING_PROP_NEW_POS=4;
integer REZZING_PROP_NAMESPACE=5;
integer REZZING_PROP_STRIDE=6;

list CopyList; // [string name, float timeout]; contains the names and the timeout for items to be copied from the parent
integer COPY_LIST_NAME=0;
integer COPY_LIST_TIMEOUT=1;
integer COPY_LIST_STRIDE=2;

integer AllowInventoryDrop;

integer CurrentPropId;

list Queue; //[string command, key id]

list CommunicationWhiteList; //[key propUuid], used to filter out unsecure messages in the listener

key AttachToKey;
integer AttachToAttachmentPoint;
float AttachToPermissionTimeout;
float AttachToAttachTimeout;
// AttachToAllowInsecureMessages
// 0: Attachments can't speak to its parent, if the owners changes during the attach
// 1: Attachments are able to speak to its parent but only if the nextOwnerPerm is noMod
// 2: Attachments are able to speak to its parent
 integer AttachToAllowInsecureMessages;
 integer AttachToTempAttach;

vector OptionScaleRef; //perhaps we want to do rezzing etc. relative to the current scale of the object. If yes: we need a reference scale.
integer OptionPropRefRoot=1; //0: prop nc pos/rot uses the prim this script is in as point of origin; 1: prop nc pos/rot uses the root prim as point of origin

vector ParentScalingFactor;
integer ParentOptionPropRefRoot=1;

//PluginCommands=[string name, integer num, integer sendToProps, integer sendUntouchedParams]
// PluginCommandsDefault: a copy from the nPose core script
list PluginCommandsDefault=[
	"PLUGINCOMMAND", PLUGIN_COMMAND_REGISTER, 0,
	"DEFAULTCARD", DEFAULT_CARD, 0,
	"OPTION", OPTIONS, 0,
	"OPTIONS", OPTIONS, 0,
	"DOCARD", DOPOSE, 0,
	"TIMER", -600, 1, //If ON_(UN)SIT is known without registration
	"TIMER_REMOVE", -601, 0 //then we also should know the TIMER(_REMOVE) commands
];
list PluginCommands;
integer PLUGIN_COMMANDS_NAME=0;
integer PLUGIN_COMMANDS_NUM=1;
integer PLUGIN_COMMANDS_SEND_UNTOUCHED=2;
integer PLUGIN_COMMANDS_STRIDE=3;

string NC_READER_CONTENT_SEPARATOR="%&§";


/*
debug(list message){
	llOwnerSay((((llGetScriptName() + "\n##########\n#>") + llDumpList2String(message,"\n#>")) + "\n##########"));
}
*/

attachDetach() {
	//if attachmentPoint is -1 than this object will be detached
	if(llGetPermissionsKey()==AttachToKey && (llGetPermissions() & PERMISSION_ATTACH)) {
		if(AttachToAttachmentPoint==-1) {
			//item should be detached
			llDetachFromAvatar();
		}
		else {
			//item should be attached
			if(AttachToTempAttach) {
				llAttachToAvatarTemp(AttachToAttachmentPoint);
			}
			else {
				llAttachToAvatar(AttachToAttachmentPoint);
			}
			//no pos rot check while attached
			TimerFlagCheckPosRot=FALSE;
		}
		AttachToKey=NULL_KEY;
		AttachToAttachmentPoint=0;
		AttachToPermissionTimeout=0;
		AttachToAttachTimeout=llGetTime()-AttachToAttachTimeout; //AttachToAttachTimeout is negative until now
	}
}

speakToParent(string msg) {
	if(ParentListenerHandle) {
		//we have a parent
		llRegionSayTo(MyParentId, ParentChatChannel, msg);
	}
}
speakToChilds(key targetUuid, string msg) {
	if(ChildListenerHandle) {
		if(targetUuid) {
			llRegionSayTo(targetUuid, ChildChatChannel, msg);
		}
		else {
			llRegionSay(ChildChatChannel, msg);
		}
	}
}

string vectorToString(vector value, integer precision) {
	return
		 "<" +
		floatToString(value.x, precision) + 
		", " +
		floatToString(value.y, precision) + 
		", " +
		floatToString(value.z, precision) + 
		">"
	;
}

string floatToString(float value,  integer precision) {
	// precision: number of decimal places
	// return (string)value;
	string valueString=(string)((float)llRound(value*llPow(10,precision))/llPow(10,precision));
	string char;
	do {
		char=llGetSubString(valueString, -1, -1);
		if(char=="." || char=="0") {
			valueString=llDeleteSubString(valueString, -1, -1);
		}
	} while (char=="0");
	return valueString;
}

list getParentPosRot() {
	if(MyParentId) {
		//get the information about the parent and the root of the parent
		list temp=llGetObjectDetails(MyParentId, [OBJECT_POS, OBJECT_ROT, OBJECT_ROOT]);
		if(!ParentOptionPropRefRoot) {
			return [llList2Vector(temp, 0), llList2Rot(temp, 1)];
		}
		temp=llGetObjectDetails(llList2Key(temp, 2), [OBJECT_POS, OBJECT_ROT]);
		return [llList2Vector(temp, 0), llList2Rot(temp, 1)];
	}
	return [ZERO_VECTOR, ZERO_ROTATION];
}

report() {
	if(MyParentId) {
		//get the information about the parent and the root of the parent
		list temp=getParentPosRot();
		vector parentPos=llList2Vector(temp, 0);
		rotation parentRot=llList2Rot(temp, 1);
		string rootName=llList2String(llGetLinkPrimitiveParams(llGetNumberOfPrims()>1, [PRIM_NAME]), 0);

		vector reportingPos;
		rotation reportingRot;
		
		MyRootPos=llGetRootPosition();
		MyRootRot=llGetRootRotation();

		reportingPos = (MyRootPos - parentPos) / parentRot;
		reportingRot = MyRootRot / parentRot;

		if(MyScalePosMode) {
			if(ParentScalingFactor.x!=0.0 && ParentScalingFactor.y!=0.0 && ParentScalingFactor.z!=0.0) {
				reportingPos = <reportingPos.x / ParentScalingFactor.x, reportingPos.y / ParentScalingFactor.y, reportingPos.z / ParentScalingFactor.z>;
			}
		}
		
		temp=[];
		if(MyQuietMode) { temp+=["quiet"]; }
		if(MyNPoseMode) { temp+=["nPose"]; }
		if(MyNoParentCheckMode) { temp+=["noParentCheck"]; }
//		if(MyIgnoreGroupWildcardsMode) { temp+=["ignoreGroupWildcards"]; }
		if(MyScalePosMode) { temp+=["scalePos"]; }
		if(MyScaleSizeMode) { temp+=["scaleSize"]; }
		string flags=llList2CSV(temp);

		list parts = ["PROP", rootName, vectorToString(reportingPos, 3), vectorToString(llRot2Euler(reportingRot) * RAD_TO_DEG, 2)];
		
		if(MyNamespace) {
			parts+=[(string)MyGroupNumber, flags, MyNamespace];
		}
		else if(flags) {
			parts+=[(string)MyGroupNumber, flags];
		}
		else if(MyGroupNumber) {
			parts+=[(string)MyGroupNumber];
		}
		
		llRegionSayTo(llGetOwner(), 0, llDumpList2String(parts, "|"));
	}
}

string addCommand(string commands, list commandWithParamList) {
	if(commands=="") {
		return llList2Json(JSON_ARRAY, [llList2Json(JSON_ARRAY, commandWithParamList)]);
	}
	else {
		return llList2Json(JSON_ARRAY, llJson2List(commands) + [llList2Json(JSON_ARRAY, commandWithParamList)]);
	}
}

executeQueue() {
	//garbarge collection RezzingPropList
	integer break;
	if(llGetListLength(RezzingPropList)) {
		float now=llGetTime();
		while(llGetListLength(RezzingPropList) && !break) {
			if(llList2Float(RezzingPropList, REZZING_PROP_TIMEOUT)<now) {
				RezzingPropList=llDeleteSubList(RezzingPropList, 0, REZZING_PROP_STRIDE-1);
			}
			else {
				break=TRUE;
			}
		}
	}
	//garbarge collection CopyList
	break=FALSE;
	if(llGetListLength(CopyList)) {
		float now=llGetTime();
		while(llGetListLength(CopyList) && !break) {
			if(llList2Float(CopyList, COPY_LIST_TIMEOUT)<now) {
				CopyList=llDeleteSubList(CopyList, 0, COPY_LIST_STRIDE-1);
			}
			else if(llGetInventoryType(llList2String(CopyList, 0))!=INVENTORY_NONE) {
				CopyList=llDeleteSubList(CopyList, 0, COPY_LIST_STRIDE-1);
			}
			else {
				break=TRUE;
			}
		}
	}

	if(!llGetListLength(CopyList) && AllowInventoryDrop) {
		AllowInventoryDrop=FALSE;
		llAllowInventoryDrop(FALSE);
	}

	break=FALSE;
	while(llGetListLength(Queue) && !break) {
		string commandString=llList2String(Queue, 0);
		list commandParts=llParseStringKeepNulls(commandString, ["|"], []);
		key id=llList2Key(Queue, 1);
		string cmd=llList2String(commandParts, 0);
		if(cmd=="COPY") {
			// copy is valid at any time
			Queue=llDeleteSubList(Queue, 0, 1);
			if(ParentListenerHandle) {
				if(llGetObjectPermMask(MASK_OWNER) & PERM_MODIFY) {
					float timeout=llGetTime()+COPY_LIST_TIMEOUT;
					list items=llCSV2List(llList2String(commandParts, 1));
					list itemsToCopy;
					while(llGetListLength(items)) {
						string item=llList2String(items, 0);
						items=llDeleteSubList(items, 0, 0);
						if(llGetInventoryType(item)==INVENTORY_NONE) {
							itemsToCopy+=item;
							CopyList+=[item, timeout];
						}
					}
					if(llGetListLength(itemsToCopy)) {
						speakToParent(addCommand("", ["CONTROL_COPY"] + itemsToCopy + [id]));
						if(llGetOwnerKey(MyParentId)!=llGetOwner() && !AllowInventoryDrop) {
							AllowInventoryDrop=TRUE;
							llAllowInventoryDrop(TRUE);
						}
					}
				}
			}
		}
		else if(cmd=="PROP") {
			if(llGetListLength(CopyList)) {
				break=TRUE;
			}
			else {
				//prop rezzing is valid if there are no copy operations
				Queue=llDeleteSubList(Queue, 0, 1);
				
				//open the listener
				if(!ChildListenerHandle) {
					ChildListenerHandle = llListen(ChildChatChannel, "", "", "");
				}
				
				string propName=llList2String(commandParts, 1);
				//Wildcard Handling
				list objects;
				if(llGetSubString(propName, -1, -1)=="*") {
					propName=llDeleteSubString(propName, -1, -1);
					integer length=llGetInventoryNumber(INVENTORY_OBJECT);
					integer index;
					for(index=0; index<length; index++) {
						string inventoryName=llGetInventoryName(INVENTORY_OBJECT, index);
						if(!llSubStringIndex(inventoryName, propName)) {
							objects+=[inventoryName];
						}
					}
				}
				else if (llGetInventoryType(propName)==INVENTORY_OBJECT){
					objects=[propName];
				}
				if(objects) {
					//we have a list of valid object(s) to rez
					integer propGroup=(integer)llList2String(commandParts, 4);
					list propFlags=llCSV2List(llToLower(llList2String(commandParts, 5)));
					string propNamespace=llStringTrim(llList2String(commandParts, 6), STRING_TRIM);
					integer scalePosMode=llListFindList(propFlags, ["scalepos"])!=-1;
					integer scaleSizeMode=llListFindList(propFlags, ["scalesize"])!=-1;
	
					//pos and rot of the prop
					vector ncPos=(vector)llList2String(commandParts, 2);
					vector scaledNcPos=ncPos;
					rotation ncRot=llEuler2Rot((vector)llList2String(commandParts, 3) * DEG_TO_RAD);
					
					//get a scaling factor
					vector scalingFactor=<1.0, 1.0, 1.0>;
					if(scalePosMode || scaleSizeMode) {
						//if we have a parent, then use the same scaling factor as our parent
						//if we are the root of the prop tree, we have to use OptionScaleRef
						if(ParentListenerHandle) {
							//we are not the root of the prop chain
							if(ParentScalingFactor.x!=0.0 && ParentScalingFactor.y!=0.0 && ParentScalingFactor.z!=0.0) {
								scalingFactor=ParentScalingFactor;
							}
						}
						else {
							//we are the root of the prop chain
							if(OptionScaleRef.x!=0.0 && OptionScaleRef.y!=0.0 && OptionScaleRef.z!=0.0) {
								vector rootScale=llList2Vector(llGetLinkPrimitiveParams((integer)(llGetNumberOfPrims()>1), [PRIM_SIZE]), 0);
								scalingFactor=<
									rootScale.x / OptionScaleRef.x,
									rootScale.y / OptionScaleRef.y,
									rootScale.z / OptionScaleRef.z
								>;
							}
						}
					}
					if(scalePosMode) {
						if(OptionPropRefRoot) {
							scaledNcPos=<
								ncPos.x * scalingFactor.x,
								ncPos.y * scalingFactor.y,
								ncPos.z * scalingFactor.z
							>;
						}
						else {
							scaledNcPos=scaledNcPos*llGetLocalRot();
							scaledNcPos=<
								ncPos.x * scalingFactor.x,
								ncPos.y * scalingFactor.y,
								ncPos.z * scalingFactor.z
							>;
							scaledNcPos=scaledNcPos/llGetLocalRot();
						}
					}
					//calculate pos and rot of the prop
					rotation propRezRot;
					vector propRezPos;
					if(OptionPropRefRoot) {
						propRezRot=ncRot * llGetRootRotation();
						propRezPos=llGetRootPosition() + scaledNcPos * llGetRootRotation();
					}
					else {
						propRezRot=ncRot * llGetRot();
						propRezPos=llGetPos() + scaledNcPos * llGetRot();
					}
					//check if the position is inside our rez range
					vector propMovePos;
					if(llVecDist(llGetPos(), propRezPos) >= 10.0) {
						propMovePos=propRezPos;
						propRezPos=llGetPos();
					}
					//rez the props
					while(llGetListLength(objects)) {
						propName=llList2String(objects, 0);
						objects=llDeleteSubList(objects, 0, 0);
						//generate PropId
						CurrentPropId++;
						if(CurrentPropId>0xff) {
							CurrentPropId=1;
						}
						//generate rezzParam
						// aaaa aaaa bbbb bbbb cccc cccc cccc cccc
						// a: propId (propId is > 0)
						// b: propGroup
						// c: unused
						integer rezParam=((CurrentPropId & 0xff) << 24) | ((propGroup & 0xff) << 16);
						//rezz the prop
						llRezAtRoot(propName, propRezPos, ZERO_VECTOR, propRezRot, rezParam);
						RezzingPropList+=[CurrentPropId, llGetTime()+PROP_TIMEOUT, llList2CSV(propFlags), scalingFactor, propMovePos, propNamespace];
					}
				}
			}
		}
		else if(!llGetListLength(RezzingPropList) && !llGetListLength(CopyList)) {
			//other commands are only valid if all props are rezzed and all items are copied
			Queue=llDeleteSubList(Queue, 0, 1);
			speakToChilds(NULL_KEY, addCommand("", commandParts + [id]));
		}
		else {
			//if there are props that are not rezzed or items that are not copied we have to wait
			break=TRUE;
		}
	}
}

die() {
	if(llGetAttached()) {
		//can't die while attached
		//maybe we want to detach me?
		AttachToKey=llGetOwner();
		AttachToAttachmentPoint=-1;
		AttachToPermissionTimeout=0;
		AttachToAttachTimeout=0;
		llRequestPermissions(AttachToKey, PERMISSION_ATTACH);
	}
	else {
		speakToParent(addCommand("", ["CONTROL_PROP_DIED", llGetKey()]));
		llDie();
	}
}

// pragma inline
integer isTarget(string targetNamesString, string targetGroupsString, string targetNamespaceString) {
	//groups:
	//0: is a special group (dies whenever the core reads a card with an ANIM command or the DEFAULTCARD)
	//1-255: normal groups
	if(targetNamespaceString!=MyNamespace) {
		return FALSE;
	}
	string rootName=llGetLinkName(llGetNumberOfPrims()>1);

	integer nameMatch = targetNamesString=="" || targetNamesString=="*";
	integer groupMatch = targetGroupsString=="" || targetGroupsString=="*";

	//group check
	if(!groupMatch) {
		list targetGroups=llCSV2List(targetGroupsString);
		if(~llListFindList(targetGroups, [(string)MyGroupNumber])) {
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
				if(!llSubStringIndex(rootName, nameToCheck)) {
					nameMatch=TRUE;
				}
			}
			else {
				if(rootName==nameToCheck) {
					nameMatch=TRUE;
				}
			}
			targetNames=llDeleteSubList(targetNames, 0, 0);
		}
	}
	return groupMatch && nameMatch;
}

init(integer start_param) {
	MyNPoseMode=1;
	MyParentId=NULL_KEY;
	MyNamespace="";
	ParentChatChannel=0;
	ChildChatChannel = (integer)("0x7F" + llGetSubString((string)llGetKey(), 0, 5));
	llListenRemove(ParentListenerHandle);
	ParentListenerHandle=0;
	llListenRemove(ChildListenerHandle);
	ChildListenerHandle=0;
	

	TimerCounter=0;
	TimerFlagCheckPosRot=FALSE;
	TimerFlagCheckParent=FALSE;
	llSetTimerEvent(TIMER_TIME);
	
	AttachToKey=NULL_KEY;
	AttachToAttachmentPoint=0;
	AttachToPermissionTimeout=0.0;
	AttachToAttachTimeout=0.0;
	
	RezzingPropList=[];
	Queue=[];
	
	MySetupFinished=0;
	
	if(start_param) {
		MyNPoseMode=0;
		//this is a child, get infos about our parent
		MyParentId=llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0);
		//open the listener, allow only the parent uuid to talk with me
		ParentChatChannel=(integer)("0x7F" + llGetSubString((string)MyParentId, 0, 5));
		ParentListenerHandle=llListen(ParentChatChannel, "", MyParentId, "");
		//extract values from the rezz param
		MyPropId=(start_param >> 24) & 0xff;
		MyGroupNumber=(start_param >> 16) & 0xff;
		//configure and set the timer
		TimerFlagCheckParent=TRUE;
		//report back to the parent
		speakToParent(addCommand("", ["CONTROL_PROP_REZZED", MyPropId, llGetKey()]));
		//store the current pos/rot. (Use the Root pos/rot because the prop gets rezzed with llRezAtRoot)
		MyRootPos=llGetRootPosition();
		MyRootRot=llGetRootRotation();
	}
}

execCommand(list commandParts, key keyPart) {
	string cmd=llList2String(commandParts, 0);
	if(cmd=="PROP_DO" ||cmd=="PROP_DO_ALL" || cmd=="PROP" || cmd=="COPY") {
		Queue+=[llDumpList2String(commandParts, "|"), keyPart];
		executeQueue();
	}
	else if(cmd=="PARENT_DO" || cmd=="PARENT_DO_ALL") {
		speakToParent(addCommand("", commandParts + [keyPart]));
	}
	else if(cmd=="DIE") {
		die();
	}
	else if(cmd=="POS") {
		//POS uses "NC" coordinates (relative to parent object and to be scalesd if the scale flag is set)
		vector newPos=(vector)llList2String(commandParts, 1);
		if(MyScalePosMode) {
			if(ParentScalingFactor.x!=0.0 && ParentScalingFactor.y!=0.0 && ParentScalingFactor.z!=0.0) {
				newPos = <newPos.x * ParentScalingFactor.x, newPos.y * ParentScalingFactor.y, newPos.z * ParentScalingFactor.z>;
			}
		}
		llSetRegionPos(llList2Vector(getParentPosRot(), 0) + newPos);
	}
	else if(cmd=="ROT") {
		//ROT uses "NC" coordinates (relative to parent object)
		llSetLinkPrimitiveParamsFast(llGetNumberOfPrims()>0, [PRIM_ROTATION, llList2Rot(getParentPosRot(), 1) * (rotation)llList2String(commandParts, 1)]);
	}
	else if(cmd=="ATTACH" || cmd=="TEMPATTACH") {
		//TEMPATTACH|target[|attachmentPoint[|allowInsecureMessages[|PermissionRequestTimeout[|AttachTimeout]]]]
		//target: Avatar UUID or seat number
		//attachmentPoint: integer, see http://wiki.secondlife.com/wiki/LlAttachToAvatarTemp
		//allowInsecureMessages: if a prop gets temp attached to a user different to the nPose object owner,
		//  the communication from this prop to its parent is blocked per default for security reasons.
		//  But there may be some cases where you want to allow the communication to the parent.
		//  0: (default) no communication to the parent if the owner changes.
		//     This is secure.
		//  1: communication to the parent is allowed if the prop is set to noMod for next owner.
		//     This should be fairly secure *** as long as the prop doesn't rez any new prop ***
		//  2: communication to the parent is allowed.
		//     This is totaly unsecure and allows the next owner to control your nPose Object
		//PermissionRequestTimeout: float, seconds, default=60; If set to 0: no timeout -> the prop will not die
		//AttachTimeout: float, seconds, default=5; (From the LSL wiki: The attach step is not guaranteed to succeed) If set to 0: no timeout -> the prop will not die

		if(!llGetAttached()) {
			AttachToTempAttach=cmd=="TEMPATTACH";
			key avatarUuid=(key)llList2String(commandParts, 1);
			if(avatarUuid) {
				//the prop must have tranfer permissions
				integer objectPerms=llGetObjectPermMask(MASK_OWNER);
				if(objectPerms & PERM_TRANSFER) {
					AttachToKey=avatarUuid;
					AttachToAttachmentPoint=(integer)llList2String(commandParts, 2);
					AttachToAllowInsecureMessages=(integer)llList2String(commandParts, 3);
					if(AttachToKey!=llGetOwner()) {
						if(AttachToAllowInsecureMessages==1) {
							objectPerms=llGetObjectPermMask(MASK_NEXT);
							if(!(objectPerms & PERM_MODIFY)) {
								speakToParent(addCommand("", ["CONTROL_ADD_TO_WHITELIST", llGetKey()]));
							}
						}
						else if(AttachToAllowInsecureMessages==2) {
							speakToParent(addCommand("", ["CONTROL_ADD_TO_WHITELIST", llGetKey()]));
						}
					}
					AttachToPermissionTimeout=PERMISSION_TIMEOUT;
					if(llStringTrim(llList2String(commandParts,4), STRING_TRIM)!="") {
						AttachToPermissionTimeout=(float)llList2String(commandParts,4);
					}
					AttachToPermissionTimeout+=llGetTime();
					
					AttachToAttachTimeout=ATTACH_TIMEOUT;
					if(llStringTrim(llList2String(commandParts,5), STRING_TRIM)!="") {
						AttachToAttachTimeout=(float)llList2String(commandParts,5);
					}
					AttachToAttachTimeout*=-1; //set it negative until it realy starts
					
					//Experience check,
					//Leona: I guess we could just simply call the llRequestExperiencePermissions because
					//we inserted a fallback in experience_permissions_denied
					list expDetails=llGetExperienceDetails(NULL_KEY);
					if(llGetListLength(expDetails) && llList2Integer(expDetails, 3)==XP_ERROR_NONE) {
						//script in experience && valid experience
						llRequestExperiencePermissions(AttachToKey, "");
					}
					else {
						llRequestPermissions(AttachToKey, PERMISSION_ATTACH);
					}
				}
			}
		}
	}
	else if(cmd=="LINKMSG" && !MyNPoseMode) {
		llMessageLinked(LINK_SET, (integer)llList2String(commandParts, 1), llList2String(commandParts, 2), (key)llList2String(commandParts, 3));
	}
	else if(!MyNPoseMode) {
		integer index=llListFindList(PluginCommands + PluginCommandsDefault, [cmd]);
		if(~index) {
			integer num=llList2Integer(PluginCommands + PluginCommandsDefault, index + PLUGIN_COMMANDS_NUM);
			string str=llDumpList2String(llDeleteSubList(commandParts, 0, 0), "|");
			llMessageLinked(LINK_SET, num, str, keyPart);
		}
		else {
			//I don't know what to do: Try to let nPose Core do the job, even if it isn't detected
			llMessageLinked(LINK_SET, DO, llDumpList2String(commandParts, "|"), keyPart);
		}
	}
	else {
		llMessageLinked(LINK_SET, DO, llDumpList2String(commandParts, "|"), keyPart);
	}
}

default {
	state_entry() {
		init(0);
	}
	link_message(integer sender, integer num, string str, key id) {
		if(num==PROP_PLUGIN) {
			list commandLines=llParseString2List(str, [NC_READER_CONTENT_SEPARATOR], []);
			while(commandLines) {
				list commandParts=llParseStringKeepNulls(llList2String(commandLines, 0), ["|"], []);
				commandLines=llDeleteSubList(commandLines, 0, 0);
				execCommand(commandParts, id);
			}
		}
		else if(num==DUMP) {
			// if a dump is requested, my childs should also make a report
			Queue+=["CONTROL_DUMP", id];
			executeQueue();
		}
		else if(num==PLUGIN_COMMAND_REGISTER || num==PLUGIN_COMMAND_REGISTER_NO_OVERWRITE) {
			//old Format (remove in nPose V5): PLUGINCOMMAND|name|num|[sendToProps[|sendUntouchedParams]]
			//new Format: PLUGINCOMMAND|name, num[, sendUntouchedParams][|name...]...
			if(!~llSubStringIndex(str, ",")) {
				//old Format:convert to new format
				str=llList2CSV(llDeleteSubList(llParseStringKeepNulls(str, ["|"], []), 2, 2));
			}
			list parts=llParseString2List(str, ["|"], []);
			while(llGetListLength(parts)) {
				list subParts=llCSV2List(llList2String(parts, 0));
				parts=llDeleteSubList(parts, 0, 0);
				string action=llList2String(subParts, PLUGIN_COMMANDS_NAME);
				integer index=llListFindList(PluginCommands, [action]);
				if(num==PLUGIN_COMMAND_REGISTER && ~index) {
					PluginCommands=llDeleteSubList(PluginCommands, index, index + PLUGIN_COMMANDS_STRIDE - 1);
				}
				if(num==PLUGIN_COMMAND_REGISTER || !~index) {
					PluginCommands+=[
						action,
						(integer)llList2String(subParts, PLUGIN_COMMANDS_NUM),
						(integer)llList2String(subParts, PLUGIN_COMMANDS_SEND_UNTOUCHED)
					];
				}
			}
		}
		else if(num == OPTIONS) {
			//save new option(s) from LINKMSG
			list optionsToSet = llParseStringKeepNulls(str, ["~","|"], []);
			integer length = llGetListLength(optionsToSet);
			integer index;
			for(index=0; index<length; ++index) {
				list optionsItems = llParseString2List(llList2String(optionsToSet, index), ["="], []);
				string optionItem = llToLower(llStringTrim(llList2String(optionsItems, 0), STRING_TRIM));
				string optionString = llList2String(optionsItems, 1);
				string optionSetting = llToLower(llStringTrim(optionString, STRING_TRIM));
				integer optionSettingFlag = optionSetting=="on" || (integer)optionSetting;

				if(optionItem == "scaleref") {OptionScaleRef = (vector)optionString;}
				else if(optionItem == "proprefroot") {OptionPropRefRoot = optionSettingFlag;}
			}
		}
		else if(num==MEMORY_USAGE) {
			llSay(0,"Memory Used by " + llGetScriptName() + ": " + (string)llGetUsedMemory() + " of " + (string)llGetMemoryLimit()
			 + ", Leaving " + (string)llGetFreeMemory() + " memory free.");
		}
	}
	
	run_time_permissions(integer perm) {
		attachDetach();
	}
	
	experience_permissions(key agent_id) {
		attachDetach();
	}
	experience_permissions_denied(key agent_id, integer reason) {
		// Permissions denied: Fallback
		if(agent_id==AttachToKey) {
			llRequestPermissions(AttachToKey, PERMISSION_ATTACH);
		}
	}
	
	attach(key id) {
		if(id) {
			AttachToAttachTimeout=0.0;
			speakToParent(addCommand("", ["CONTROL_PROP_ATTACHED", llList2String(llGetLinkPrimitiveParams(llGetNumberOfPrims()>1, [PRIM_NAME]), 0), MyGroupNumber, llGetKey()]));
		}
		else {
			speakToParent(addCommand("", ["CONTROL_PROP_DETACHED", llList2String(llGetLinkPrimitiveParams(llGetNumberOfPrims()>1, [PRIM_NAME]), 0), MyGroupNumber, llGetKey()]));
		}
	}

	listen(integer channel, string name, key id, string message) {
		//security
		//we only allow messages from objects that are sharing the same owner (props)
		//or that came from our parent
		//or that are in our white list (some tempAttached props)
		if(llGetOwnerKey(id)!=llGetOwner()) {
			if(id!=MyParentId) {
				if(!~llListFindList(CommunicationWhiteList, [id])) {
					return;
				}
			}
		}
		//check if the message is in JSON format
		if(llJsonValueType(message, [])!=JSON_ARRAY) {
			return;
		}
		list commandLines=llJson2List(message);
		while(llGetListLength(commandLines)) {
			list commandParts=llJson2List(llList2String(commandLines, 0));
			commandLines=llDeleteSubList(commandLines, 0, 0);
			string cmd=llList2String(commandParts, 0);
			//each message has a trailing key. extract and remove it
			key keyPart=(key)llList2String(commandParts, -1);
			commandParts=llDeleteSubList(commandParts, -1, -1);

			if(channel==ParentChatChannel) {
				//messages from my parent
				if(cmd=="CONTROL_SET_POS_GLOBAL") {
					llSetRegionPos((vector)llList2String(commandParts, 1));
					MyRootRot=llGetRootRotation();
					MyRootPos=llGetRootPosition();
				}
				else if(cmd=="CONTROL_SET_FLAGS") {
					list myFlags=llCSV2List(llToLower(llList2String(commandParts, 1)));
					MyQuietMode=llListFindList(myFlags, ["quiet"])!=-1;
					MyNPoseMode=llListFindList(myFlags, ["npose"])!=-1;
					MyNoParentCheckMode=llListFindList(myFlags, ["noparentcheck"])!=-1;
//					MyIgnoreGroupWildcardsMode=llListFindList(myFlags, ["ignoregroupwildcards"])!=-1;
					MyScalePosMode=llListFindList(myFlags, ["scalepos"])!=-1;
					MyScaleSizeMode=llListFindList(myFlags, ["scalesize"])!=-1;
					TimerFlagCheckPosRot=!MyQuietMode;
					TimerFlagCheckParent=!MyNoParentCheckMode;
				}
				else if(cmd=="CONTROL_SET_OTHER") {
					MySetupFinished=MySetupFinished | 0x1;
					ParentOptionPropRefRoot=(integer)llList2String(commandParts, 1);
					ParentScalingFactor=(vector)llList2String(commandParts, 2);
					MyNamespace=llList2String(commandParts, 3);
					if(MyScaleSizeMode) {
						//scale each prim in this linkset
						//there is no way to do a correct non-uniform scaling when the child prims don't have a local rot of exactly 0°, 90°, 180° or 270° around the 3 axis
						//so there are 3 ways to scale:
						// a) support non-uniform scaling for all 4 rotations named above: complex -> too much memory
						// b) support non-uniform scaling but only if all child rotations are zero (or 180°): easy
						// c) only support uniform scaling: trivial
						// I choose b) because it may be handy in some cases
						//note: If the Child Prim Rotations are != 0° or != 180° and we do a non-uniform scaling, this code will produce wrong results 
						if(ParentScalingFactor.x!=1.0 || ParentScalingFactor.y!=1.0 || ParentScalingFactor.z!=1.0) {
							integer count=llGetObjectPrimCount(llGetKey());
							if(!count) {
								count=llGetNumberOfPrims();
							}
							//the root prim doesn't need to be positioned localy
							vector rootSize=llList2Vector(llGetLinkPrimitiveParams(count>1, [PRIM_SIZE]), 0);
							llSetLinkPrimitiveParamsFast(count>1, [
								PRIM_SIZE, <rootSize.x * ParentScalingFactor.x, rootSize.y * ParentScalingFactor.y, rootSize.z * ParentScalingFactor.z>
							]);
							//scale and position the child prims
							integer index;
							for(index=2; index<=count; index++) {
								list temp=llGetLinkPrimitiveParams(index, [PRIM_POS_LOCAL, PRIM_SIZE]);
								vector localPos=llList2Vector(temp, 0);
								vector localSize=llList2Vector(temp, 1);
								
								llSetLinkPrimitiveParamsFast(index, [
									PRIM_POS_LOCAL, <localPos.x * ParentScalingFactor.x, localPos.y * ParentScalingFactor.y, localPos.z * ParentScalingFactor.z>,
									PRIM_SIZE, <localSize.x * ParentScalingFactor.x, localSize.y * ParentScalingFactor.y, localSize.z * ParentScalingFactor.z>
								]);
							}
						}
					}
					if(MySetupFinished == 0x3) {
						speakToParent(addCommand("", ["CONTROL_SETUP_FINISHED", MyPropId, MyGroupNumber, ""]));
					}
					
				}
				else if(cmd=="CONTROL_SET_PLUGIN_COMMANDS") {
					MySetupFinished=MySetupFinished | 0x2;
					commandParts=llDeleteSubList(commandParts, 0, 0);
					integer index;
					integer length=llGetListLength(commandParts);
					list tempList;
					string str;
					for(index=0; index<length; index+=PLUGIN_COMMANDS_STRIDE) {
						tempList+=[llList2CSV(llList2List(commandParts, index, index + PLUGIN_COMMANDS_STRIDE -1))];
					}
					llMessageLinked(LINK_SET, PLUGIN_COMMAND_REGISTER_NO_OVERWRITE, llDumpList2String(tempList, "|"), keyPart);
					if(MySetupFinished == 0x3) {
						speakToParent(addCommand("", ["CONTROL_SETUP_FINISHED", MyPropId, MyGroupNumber, ""]));
					}
				}
				else if(cmd=="CONTROL_DUMP") {
					//TODO: should we send this message to our childs too? 
					if(MyNamespace=="") {
						report();
					}
				}
				else if(cmd=="PROP_DO" || cmd=="PROP_DO_ALL") {
					if(cmd=="PROP_DO_ALL") {
						execCommand(commandParts, keyPart);
					}
					if(isTarget(llList2String(commandParts, 1), llList2String(commandParts, 2), llList2String(commandParts, 3))) {
						execCommand(llDeleteSubList(commandParts, 0, 3), keyPart);
					}
				}
			}
			else if(channel==ChildChatChannel) {
				//messages from my childs
				if(cmd=="CONTROL_PROP_REZZED") {
					integer propId=(integer)llList2String(commandParts, 1);
					integer index=llListFindList(RezzingPropList, [propId]);
					if(~index) {
						string childCommands;
						vector newPos=llList2Vector(RezzingPropList, index+REZZING_PROP_NEW_POS);
						if(newPos!=ZERO_VECTOR) {
							childCommands=addCommand("", [
								"CONTROL_SET_POS_GLOBAL",
								newPos,
								""
							]);
						}
						childCommands=addCommand(childCommands, [
							"CONTROL_SET_FLAGS",
							llList2String(RezzingPropList, index+REZZING_PROP_FLAGS),
							""
						]);
						childCommands=addCommand(childCommands, [
							"CONTROL_SET_OTHER",
							OptionPropRefRoot,
							llList2Vector(RezzingPropList, index+REZZING_PROP_SCALING_FACTOR),
							llList2String(RezzingPropList, index+REZZING_PROP_NAMESPACE),
							""
						]);
						speakToChilds(id, childCommands);
						childCommands=addCommand("", ["CONTROL_SET_PLUGIN_COMMANDS"] + PluginCommands + [""]);
						speakToChilds(id, childCommands);
					}
				}
				else if(cmd=="CONTROL_SETUP_FINISHED") {
					integer propId=(integer)llList2String(commandParts, 1);
					integer index=llListFindList(RezzingPropList, [propId]);
					if(~index) {
						RezzingPropList=llDeleteSubList(RezzingPropList, index, index+REZZING_PROP_STRIDE-1);
					}
					llMessageLinked(
						LINK_SET,
						ON_PROP_REZZED,
						llDumpList2String([name, id, channel] + llDeleteSubList(commandParts, 0, 0), "|"),
						NULL_KEY
					);
					executeQueue();
				}
				else if(cmd=="CONTROL_PROP_DIED") {
					integer index=llListFindList(CommunicationWhiteList, [id]);
					if(~index) {
						CommunicationWhiteList=llDeleteSubList(CommunicationWhiteList, index, index);
					}
				}
				else if(cmd=="CONTROL_ADD_TO_WHITELIST") {
					integer index=llListFindList(CommunicationWhiteList, [id]);
					if(!~index) {
						CommunicationWhiteList+=id;
					}
				}
				else if(cmd=="CONTROL_COPY") {
					//allow copy only to objects that are sharing the same owner
					if(llGetOwnerKey(id)==llGetOwner()) {
						list items=llDeleteSubList(commandParts, 0, 0);
						while(llGetListLength(items)) {
							string item=llList2String(items, 0);
							items=llDeleteSubList(items, 0, 0);
							if(llGetInventoryType(item)!=INVENTORY_NONE && llGetInventoryType(item)!=INVENTORY_SCRIPT) {
								integer perm=llGetInventoryPermMask(item, MASK_OWNER);
								if(perm & PERM_COPY) {
									llGiveInventory(id, item);
								}
							}
						}
					}
				}
				else if(cmd=="PARENT_DO_ALL") {
					execCommand(commandParts, keyPart);
					execCommand(llDeleteSubList(commandParts, 0, 0), keyPart);
				}
				else if(cmd=="PARENT_DO") {
					execCommand(llDeleteSubList(commandParts, 0, 0), keyPart);
				}
			}
		}
	}

	on_rez(integer start_param) {
		init(start_param);
	}
	changed(integer change) {
		if(change & CHANGED_INVENTORY) {
			if(llGetListLength(CopyList)) {
				executeQueue();
			}
		}
	}

/*
// This isn't secure, because the new owner may simply delete this script (and add a new one)
	changed(integer change) {
		if(change & CHANGED_INVENTORY) {
			if(ParentListenerHandle) {
				if(llGetAttached()) {
					if(llGetOwnerKey(MyParentId)!=llGetOwner()) {
						// I'm an (temp) attachment and somebody changed my inventory
						// -> this could be an attempt to add a malicious script
						die();
					}
				}
			}
		}
	}
*/
	timer() {
		//fast timer
		TimerCounter++;
		executeQueue();
		if(!(TimerCounter % SLOW_TIMER_FACTOR)) {
			//slow timer
			if(TimerFlagCheckPosRot) {
				//pos,rot check
				if(MyRootPos!=llGetRootPosition() || MyRootRot!=llGetRootRotation()) {
					report();
				}
			}
			if(TimerFlagCheckParent) {
				if(llKey2Name(MyParentId)=="") {
					//lost my Parent
					die();
				}
			}
			if(AttachToPermissionTimeout>0.0) {
				if(AttachToPermissionTimeout<llGetTime()) {
					//permission request timeout
					die();
				}
			}
			if(AttachToAttachTimeout>0.0) {
				if(AttachToAttachTimeout<llGetTime()) {
					//The attach step is not guaranteed to succeed and it seems that it failed
					die();
				}
			}
		}
		if(!(TimerCounter % VERY_SLOW_TIMER_FACTOR)) {
			//Garbarge collection White List
			integer index;
			integer length=llGetListLength(CommunicationWhiteList);
			for(index=0; index<length; index++) {
				if(llKey2Name(llList2Key(CommunicationWhiteList, index))=="") {
					CommunicationWhiteList=llDeleteSubList(CommunicationWhiteList, index, index);
					index--;
					length--;
				}
			}
		}
	}
}
