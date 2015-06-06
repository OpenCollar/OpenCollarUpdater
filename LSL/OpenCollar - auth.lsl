////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                               OpenCollar - auth                                //
//                                 version 3.994                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

key g_kWearer;

list g_lOwners;//strided list in form key,name
list g_lTrusted;//strided list in the form key,name
//list g_lSecOwners;
list g_lBlockList;//list of blacklisted UUID
list g_lTempOwners;//list of temp owners UUID.  Temp owner is just like normal owner, but can't add new owners.

key g_kGroup = "";
string g_sGroupName;
integer g_iGroupEnabled = FALSE;

string g_sParentMenu = "Main";
string g_sSubMenu = "Access";
integer g_iRunawayDisable=0;

//string g_sPrefix;

list g_lQueryId; //5 strided list of dataserver/http request: key, uuid, requestType, kAv, remenu.  For AV name/group name  lookups
integer g_iQueryStride=5;

//added for attachment auth, for now taken out as we do not support attachment auth 
//integer g_iInterfaceChannel;

//string g_sAuthError = "Access denied.";

//MESSAGE MAP
integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;  // new for safeword
integer CMD_BLOCKED = 520;
// added so when the sub is locked out they can use postions
//integer CMD_WEARERLOCKEDOUT = 521;

//integer POPUP_HELP = 1001;
integer NOTIFY = 1002;
integer NOTIFY_OWNERS = 1003;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

//integer MENUNAME_REQUEST = 3000;
//integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
//integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

//integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
//integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer FIND_AGENT = -9005;

//added for attachment auth (garvin)
integer ATTACHMENT_REQUEST = 600;
integer ATTACHMENT_RESPONSE = 601;
//new evolution style to handle attachment auth
integer INTERFACE_REQUEST  = -9006;
integer INTERFACE_RESPONSE = -9007;

string UPMENU = "BACK";

integer g_iOpenAccess; // 0: disabled, 1: openaccess
integer g_iLimitRange=1; // 0: disabled, 1: limited

list g_lMenuIDs;
integer g_iMenuStride = 3;

key REQUEST_KEY;

string g_sSettingToken = "auth_";
//string g_sGlobalToken = "global_";
/*
integer g_iProfiled=1;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to 
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}
*/

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) { //we've alread given a menu to this user.  overwrite their entry
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    } else { //we've not already given this user a menu. append to list
        g_lMenuIDs += [kID, kMenuID, sName];
    }
} 
/*
Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}*/

FetchAvi(integer iAuth, string sType, string sName, key kAv) {
    if (sName == "") sName = " ";
    string out = llDumpList2String(["getavi_", g_sSettingToken, kAv, iAuth, sType, sName], "|");
    integer i = 0;
    list src = g_lOwners;
    if (sType == "tempowner") src += g_lTempOwners;
    if (sType == "trust") src += g_lTrusted;
    else if (sType == "block") src = g_lBlockList;
    list exclude; // build list of existing-listed keys to exclude from name search
    for (; i < llGetListLength(src); i += 2) {
        exclude += [llList2String(src, i)];
    }
    if (llGetListLength(exclude))
        out += "|" + llDumpList2String(exclude, ",");
    llMessageLinked(LINK_THIS, FIND_AGENT, out, REQUEST_KEY = llGenerateKey());
}

AuthMenu(key kAv, integer iAuth) {
    string sPrompt = "\n\"My lips may promise...\n but my heart is a whore.\"";
    list lButtons = ["✚ Owner", "✚ Trusted", "✚ Blocked", "♻ Owner", "♻ Trusted", "♻ Blocked"];

    if (g_kGroup=="") lButtons += ["Group ☐"];    //set group
    else lButtons += ["Group ☒"];    //unset group
    if (g_iOpenAccess) lButtons += ["Public ☒"];    //set open access
    else lButtons += ["Public ☐"];    //unset open access
    if (g_iLimitRange) lButtons += ["LimitRange ☒"];    //set ranged
    else lButtons += ["LimitRange ☐"];    //unset open ranged
    
    lButtons += ["Runaway","Access List"];
    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, "Auth");
}


RemPersonMenu(key kID, string sToken, integer iAuth) {
    list lPeople;
    if (sToken=="owner") lPeople=g_lOwners;
    else if (sToken=="tempowner") lPeople=g_lTempOwners;
    else if (sToken=="trust") lPeople=g_lTrusted;
    else if (sToken=="block") lPeople=g_lBlockList;
    else return;
    if (llGetListLength(lPeople)){
        string sPrompt = "\nChoose the person to remove:\n";
        list lButtons;
        integer iNum= llGetListLength(lPeople);
        integer n;
        for(;n<iNum;n=n+2) {
            string sName = llList2String(lPeople,n);
            if (sName) {
                //sPrompt +=sName;
                lButtons += [sName];
            }
        }
 /*       for (n=1; n <= iNum/2; n = n + 1) {
            string sName = llList2String(lPeople, 2*n-1);
            if (sName != "") {
                sPrompt += "\n" + (string)(n) + " - " + sName;
                lButtons += [(string)(n)];
            }
        }*/
       // lButtons += ["Remove All"];
        Dialog(kID, sPrompt, lButtons, ["Remove All",UPMENU], -1, iAuth, "remove"+sToken);
    } else {
        llMessageLinked(LINK_SET,NOTIFY,"0"+"The list is empty",kID);
        AuthMenu(kID, iAuth);
    }
}
    
RemovePerson(string sName, string sToken, key kCmdr) {
    //where "lPeople" is a 2-strided list in form key,name
    //looks for strides identified by "name", removes them if found, and returns the list
    //also handles notifications so as to reduce code duplication in the link message event
    //Debug("removing: " + sName);
    //all our comparisons will be cast to lower case first
    list lPeople;
    if (sToken=="owner") lPeople=g_lOwners;
    else if (sToken=="tempowner") lPeople=g_lTempOwners;
    else if (sToken=="trust") lPeople=g_lTrusted;
    else if (sToken=="block") lPeople=g_lBlockList;
    else return;
// ~ is bitwise NOT which is used for the llListFindList function to simply turn the result "-1" for "not found" into a 0 (FALSE) 
    if (~llListFindList(g_lTempOwners,[(string)kCmdr]) && ! ~llListFindList(g_lOwners,[(string)kCmdr]) && sToken != "tempowner"){
        llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kCmdr);
        //Notify(kCmdr,g_sAuthError,FALSE);
        return;
    }
    //simple conversion from ID to Name when menus are used to remove 
    if((key)sName) sName = llList2String(lPeople,llListFindList(lPeople,[(string)sName])+1);
    sName = llToLower(sName);
    integer iFound=FALSE;
    integer iNumPeople= llGetListLength(lPeople)/2;
    while (iNumPeople--) {
        string sThisName = llToLower(llList2String(lPeople, iNumPeople*2+1));
        //Debug("checking " + sThisName);
        if (sName == sThisName || sName == "remove all") {   //remove name and key
            if (sToken == "owner" || sToken == "trust") {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Your access to %WEARERNAME%'s %DEVICETYPE% has been revoked.",llList2String(lPeople,iNumPeople*2));
               // llRegionSayTo(g_kWearer, g_iInterfaceChannel, "CollarCommand|499|OwnerChange"); //tell attachments owner changed
            }
            llMessageLinked(LINK_SET,NOTIFY,"0"+"secondlife:///app/agent/"+llList2String(lPeople,iNumPeople*2)+"/about removed from " + sToken + " list.",kCmdr);
           // llMessageLinked(LINK_SET,NOTIFY,"0"+sThisName + " removed from " + sToken + " list.",kCmdr);
            lPeople = llDeleteSubList(lPeople, iNumPeople*2, iNumPeople*2+1);
            iFound=TRUE;
        }
    }
    if (iFound){
         string sOldToken=sToken;
         if (sToken == "secowner") sOldToken+="s";
            if (llGetListLength(lPeople)>0)
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + sOldToken + "=" + llDumpList2String(lPeople, ","), "");
            else
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + sOldToken, "");
        //store temp list
        if (sToken=="owner") {
            g_lOwners = lPeople;
            if (llGetListLength(g_lOwners)) SayOwners();
        }
        else if (sToken=="tempowner") g_lTempOwners = lPeople;
        else if (sToken=="trust") g_lTrusted = lPeople;
        else if (sToken=="block") g_lBlockList = lPeople;
    } else 
        llMessageLinked(LINK_SET,NOTIFY,"0"+"\""+sName + "\" is not in "+sToken+" list.",kCmdr);
        //Notify(kCmdr, "Error: '" + sName + "' not in list.",FALSE);
}

AddUniquePerson(key kPerson, string sName, string sToken, key kAv) {
    list lPeople;
    //Debug(llKey2Name(kAv)+" is adding "+llKey2Name(kPerson)+" to list "+sToken);
    if (~llListFindList(g_lTempOwners,[(string)kAv]) && ! ~llListFindList(g_lOwners,[(string)kAv]) && sToken != "tempowner")
        llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kAv); //Notify(kAv,g_sAuthError,FALSE);
    else {
        if (sToken=="owner") {
            lPeople=g_lOwners;
            if (llGetListLength (lPeople) >=6) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nSorry, we reached a limit!\n\nThree people at a time can have this role.\n",kAv);
                //Notify(kAv, "\n\nSorry, we reached a limit!\n\nSix people at a time can have this role.\n",FALSE);
                return;
            }
        } else if (sToken=="trust") {
            lPeople=g_lTrusted;
            if (llGetListLength (lPeople) >=30) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nSorry, we reached a limit!\n\n15 people at a time can have this role.\n",kAv);
                //Notify(kAv, "\n\nSorry, we reached a limit!\n\nTwelve people at a time can have this role.\n",FALSE);
                return;
            } else if (~llListFindList(g_lOwners,[(string)kPerson])) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nOops!\n\n"+sName+" is already Owner! You should really trust them.\n",kAv);
               //Notify(kAv, "\n\nOops!\n\n"+sName+" is already Owner! You should really trust them.\n",FALSE);
                return;
            }
        } else if (sToken=="tempowner") {
            lPeople=g_lTempOwners;
            if (llGetListLength (lPeople) >=2) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nSorry!\n\nYou can only be captured by one person at a time.\n",kAv);
                //Notify(kAv, "\n\nSorry!\n\nYou can only be captured by one person at a time.\n",FALSE);
                return;
            }
        } else if (sToken=="block") {
            lPeople=g_lBlockList;
            if (llGetListLength (lPeople) >=18) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nOops!\n\nYour Blacklist is already full.\n",kAv);
                //Notify(kAv, "\n\nOops!\n\nYour Blacklist is already full.\n",FALSE);
                return;
            } else if (~llListFindList(g_lTrusted,[(string)kPerson])) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nOops!\n\nYou trust "+sName+". If you really want to block "+sName+" then you should remove them as trusted first.\n",kAv);
                //Notify(kAv, "\n\nOops!\n\nYou trust "+sName+". If you really want to block "+sName+" then you should remove them as trusted first.\n",FALSE);
                return;
            } else if (~llListFindList(g_lOwners,[(string)kPerson])) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nOops!\n\n"+sName+" is Owner! Remove them as owner before you block them.\n",kAv);
                //Notify(kAv, "\n\nOops!\n\n"+sName+" is Owner! Remove them as owner before you block them.\n",FALSE);
                return;
            }
        } else
            return;
        
        if (! ~llListFindList(lPeople, [(string)kPerson])) //owner is not already in list.  add him/her
            lPeople += [(string)kPerson, sName];

        if (kPerson != g_kWearer) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Building relationship...",g_kWearer);
            //Notify(g_kWearer, "Building relationship...", FALSE);
            if (sToken == "owner") {
                if (~llListFindList(g_lTrusted,[(string)kPerson])) RemovePerson(sName, "trust", kAv);
                if (~llListFindList(g_lBlockList,[(string)kPerson])) RemovePerson(sName, "block", kAv);
                llMessageLinked(LINK_SET,NOTIFY,"0"+"You belong to secondlife:///app/agent/"+(string)kPerson+"/about now!",g_kWearer);
                //Notify(g_kWearer, "You belong to " + sName +" now!", FALSE);
                llPlaySound("1ec0f327-df7f-9b02-26b2-8de6bae7f9d5",1.0);
            }
            else if (sToken == "trust") {
                if (~llListFindList(g_lBlockList,[(string)kPerson])) RemovePerson(sName, "block", kAv);
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Looks like secondlife:///app/agent/"+(string)kPerson+"/about is someone you can trust!",g_kWearer);
                //Notify(g_kWearer, "Looks like " + sName +" is someone you can trust!", FALSE);
                llPlaySound("def49973-5aa6-b79d-8c0e-2976d5b6d07a",1.0);
            }
        }

        if (sToken == "owner") {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\n%WEARERNAME% belongs to you now.\n\nSee [http://www.virtualdisgrace.com/collar here] what that means!\n",kPerson);
            //Notify(kPerson, "\n\n"+ g_sWearerName + " belongs to you now.\n\nSee [http://www.virtualdisgrace.com/collar here] what that means!\n",FALSE);
           // llRegionSayTo(g_kWearer, g_iInterfaceChannel, "CollarCommand|499|OwnerChange"); //tell attachments owner changed
        }
        
        if (sToken == "trust") {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\n%WEARERNAME% seems to trust you.\n\nSee [http://www.virtualdisgrace.com/collar here] what that means!\n",kPerson);
            //Notify(kPerson, "\n\n"+ g_sWearerName + " seems to trust you.\n\nSee [http://www.virtualdisgrace.com/collar here] what that means!\n",FALSE);
           // llRegionSayTo(g_kWearer, g_iInterfaceChannel, "CollarCommand|499|OwnerChange"); //tell attachments owner changed
        }
        
        string sOldToken=sToken;
        if (sToken == "secowner") sOldToken+="s";
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + sOldToken + "=" + llDumpList2String(lPeople, ","), "");
        
        if (sToken=="owner") {
            g_lOwners = lPeople;
            if (llGetListLength(g_lOwners)>2) SayOwners();
        }
        else if (sToken=="trust") g_lTrusted = lPeople;
        else if (sToken=="tempowner") g_lTempOwners = lPeople;
        else if (sToken=="block") g_lBlockList = lPeople;
    }
}

SayOwners() {  // Give a "you are owned by" message, nicely formatted.
    integer iCount = llGetListLength(g_lOwners);
    if (iCount) {
        list lTemp = g_lOwners;
        integer index = llListFindList(lTemp, [(string)g_kWearer]);
        //if wearer is also owner, move the key to the end of the list.
        if (~index) lTemp = llDeleteSubList(lTemp,index,index+1) + [g_kWearer];
        string sMsg = "You belong to ";
        if (iCount == 2) {
            if (llList2Key(lTemp,0)==g_kWearer)
                sMsg += "yourself.";
            else
                sMsg += "secondlife:///app/agent/"+llList2String(lTemp,0)+"/about.";
        } else if (iCount == 4) {
            sMsg +=  "secondlife:///app/agent/"+llList2String(lTemp,0)+"/about and ";
            if (llList2Key(lTemp,2)==g_kWearer)
                sMsg += "yourself.";                
            else
                sMsg += "secondlife:///app/agent/"+llList2String(lTemp,2)+"/about.";
        } else {
            index=0;
            do {
                sMsg += "secondlife:///app/agent/"+llList2String(lTemp,index)+"/about, ";
                index+=2;
            } while (index<iCount-2);
            if (llList2Key(lTemp,index) == g_kWearer)
                sMsg += "and yourself.";
            else 
                sMsg += "and "+"secondlife:///app/agent/"+llList2String(lTemp,index)+"/about.";
        }
        llMessageLinked(LINK_SET,NOTIFY,"0"+sMsg,g_kWearer);
 //       Debug("Lists Loaded!");
    }
}

/*SetPrefix(string sValue) {
    if (sValue != "auto") g_sPrefix = sValue;
    else g_sPrefix = llToLower(llGetSubString(llKey2Name(llGetOwner()), 0,1));
}*/

integer in_range(key kID) {
    if (g_iLimitRange) {
        if (llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(kID, [OBJECT_POS]), 0)) > 20) { //if the distance between my position and their position  > 20
            llDialog(kID, "\nNot in range...", [], (integer)llFrand(1000000)+99999);
            return FALSE;
        }
    }
    return TRUE;
}

integer Auth(string sObjID, integer iAttachment) {
    string sID = (string)llGetOwnerKey(sObjID); // if sObjID is an avatar key, then sID is the same key
    integer iNum;
    if (~llListFindList(g_lOwners+g_lTempOwners, [sID]))
        iNum = CMD_OWNER;
    else if (llGetListLength(g_lOwners+g_lTempOwners) == 0 && sID == (string)g_kWearer)
        //if no owners set, then wearer's cmds have owner auth
        iNum = CMD_OWNER;
    else if (~llListFindList(g_lBlockList, [sID]))
        iNum = CMD_BLOCKED;
    else if (~llListFindList(g_lTrusted, [sID]))
        iNum = CMD_TRUSTED;
    else if (sID == (string)g_kWearer)
        iNum = CMD_WEARER;
    else if (g_iOpenAccess)
        if (in_range((key)sID))
            iNum = CMD_GROUP;
        else
            iNum = CMD_EVERYONE;
    else if (g_iGroupEnabled && (string)llGetObjectDetails((key)sObjID, [OBJECT_GROUP]) == (string)g_kGroup && (key)sID != g_kWearer)  //meaning that the command came from an object set to our control group, and is not owned by the wearer
        iNum = CMD_GROUP;
    else if (llSameGroup(sID) && g_iGroupEnabled && sID != (string)g_kWearer)
        if (in_range((key)sID))
            iNum = CMD_GROUP;
        else
            iNum = CMD_EVERYONE;
    else
        iNum = CMD_EVERYONE;
    //Debug("Authed as "+(string)iNum);
    return iNum;
}

// returns TRUE if eligible (AUTHED link message number)
integer UserCommand(integer iNum, string sStr, key kID, integer iRemenu) { // here iNum: auth value, sStr: user command, kID: avatar id
   // Debug ("UserCommand("+(string)iNum+","+sStr+","+(string)kID+")");
    
    if (iNum == CMD_EVERYONE) return TRUE;  // No command for people with no privilege in this plugin.
    else if (iNum > CMD_EVERYONE || iNum < CMD_OWNER) return FALSE; // sanity check
    string sMessage=llToLower(sStr);
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llList2String(lParams, 0);
    if (sStr == "menu "+g_sSubMenu) AuthMenu(kID, iNum);
    else if (sStr == "list") {   //say owner, secowners, group
        if (iNum == CMD_OWNER || kID == g_kWearer) {
            //Do Owners list
            integer iLength = llGetListLength(g_lOwners);
            string sOutput="";
            while (iLength)
                sOutput += "\n" + llList2String(g_lOwners, --iLength) + " (" + llList2String(g_lOwners,  --iLength) + ")";
            if (sOutput) llMessageLinked(LINK_SET,NOTIFY,"0"+"Owners: "+sOutput,kID); 
            else llMessageLinked(LINK_SET,NOTIFY,"0"+"Owners: none",kID); 
            //Do TempOwners list
            iLength = llGetListLength(g_lTempOwners);
            sOutput="";
            while (iLength)
                sOutput += "\n" + llList2String(g_lTempOwners, --iLength) + " (" + llList2String(g_lTempOwners,  --iLength) + ")";
            if (sOutput) llMessageLinked(LINK_SET,NOTIFY,"0"+"Temporary Owner: "+sOutput,kID); 
            //Do Trusted list
            iLength = llGetListLength(g_lTrusted);
            sOutput="";
            while (iLength)
                sOutput += "\n" + llList2String(g_lTrusted, --iLength) + " (" + llList2String(g_lTrusted, --iLength) + ")";
            if (sOutput) llMessageLinked(LINK_SET,NOTIFY,"0"+"Trusted: "+sOutput,kID); 
            iLength = llGetListLength(g_lBlockList);
            sOutput="";
            while (iLength)
                sOutput += "\n" + llList2String(g_lBlockList, --iLength) + " (" + llList2String(g_lBlockList, --iLength) + ")";
            if (sOutput) llMessageLinked(LINK_SET,NOTIFY,"0"+"Blocked: "+sOutput,kID);
            if (g_sGroupName) llMessageLinked(LINK_SET,NOTIFY,"0"+"Group: "+g_sGroupName,kID); 
            if (g_kGroup) llMessageLinked(LINK_SET,NOTIFY,"0"+"Group Key: "+(string)g_kGroup,kID); 
            sOutput="closed"; 
            if (g_iOpenAccess) sOutput="open"; 
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Public Access: "+ sOutput,kID);
            //sOutput="closed"; 
            //if (g_iLimitRange) sOutput="true";
            //Notify(kID, "LimitRange: "+ sOutput,FALSE);
        }
        else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID); //Notify(kID,g_sAuthError,FALSE);
        if (iRemenu) AuthMenu(kID, iNum);
    } else if (sStr == "owners" || sStr == "access") {   //give owner menu
        AuthMenu(kID, iNum);
//    } else if (sStr=="give hud" || sMessage == "give hud") {
//        if (kID == g_kWearer) llGiveInventory(kID,"Virtual Disgrace - Collar HUD");
//        else llGiveInventory(kID,"Virtual Disgrace - Owner HUD");
//        if (iRemenu) AuthMenu(kID, iNum);
    } else if (sMessage == "owner" && iRemenu==FALSE) { //request for access menu from chat
        AuthMenu(kID, iNum);
    } else if (sCommand == "owner" || sCommand == "tempowner" || sCommand == "trust" || sCommand == "block") { //add a person to a list
        string sTmpName = llDumpList2String(llDeleteSubList(lParams,0,0), " "); //get full name
        if (iNum!=CMD_OWNER && !( sCommand == "trust" && kID==g_kWearer )) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID); //Notify(kID,g_sAuthError, FALSE);
            if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
        } else if ((key)sTmpName){
            g_lQueryId+=[llRequestAgentData( sTmpName, DATA_NAME ),sTmpName,sCommand, kID, iRemenu];
            if (iRemenu) FetchAvi(Auth(kID,FALSE), sCommand, sTmpName, kID);
        } else
            FetchAvi(iNum, sCommand, sTmpName, kID);
    } else if (llSubStringIndex(sCommand,"remove")==0) { //remove person from a list
        if (sCommand=="remowners") sCommand="removeowner";
        //Debug("got command "+sCommand);
        string sToken = llGetSubString(sCommand,6,-1);
        //Debug("got token "+sToken);
        string sTmpName = llDumpList2String(llDeleteSubList(lParams,0,0), " "); //get full name
        if (iNum!=CMD_OWNER && !( sToken == "trust" && kID==g_kWearer )) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID); //Notify(kID,g_sAuthError, FALSE);
            if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
        } else if (sTmpName=="") RemPersonMenu(kID, sToken, iNum);
        else {
            RemovePerson(sTmpName, sToken, kID);
            if (iRemenu) RemPersonMenu(kID, sToken, Auth(kID,FALSE));
        }
     } else if (sCommand == "setgroup") {
        if (iNum==CMD_OWNER){
            //if key provided use that, else read current group
            if ((key)(llList2String(lParams, -1))) g_kGroup = (key)llList2String(lParams, -1);
            else g_kGroup = (key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0); //record current group key

            if (g_kGroup != "") {
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "group=" + (string)g_kGroup, "");
                g_iGroupEnabled = TRUE;
             
                key kGroupHTTPID = llHTTPRequest("http://world.secondlife.com/group/" + (string)g_kGroup, [], "");   //get group name from world api
                g_lQueryId+=[kGroupHTTPID,"","group", kID, FALSE];
                llMessageLinked(LINK_SET, RLV_CMD, "setgroup=n", "auth");
            }
        } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID); //Notify(kID,g_sAuthError, FALSE);
        if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sCommand == "setgroupname") {
        if (iNum==CMD_OWNER){
            g_sGroupName = llDumpList2String(llList2List(lParams, 1, -1), " ");
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "groupname=" + g_sGroupName, "");
        } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID); //Notify(kID,g_sAuthError, FALSE);
    } else if (sCommand == "unsetgroup") {
        if (iNum==CMD_OWNER){
            g_kGroup = "";
            g_sGroupName = "";
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "group", "");
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "groupname", "");
            g_iGroupEnabled = FALSE;
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Group unset.",kID); //Notify(kID, "Group unset.", FALSE);
           // llRegionSayTo(g_kWearer, g_iInterfaceChannel, "CollarCommand|499|OwnerChange"); //tell attachments owner changed
            llMessageLinked(LINK_SET, RLV_CMD, "setgroup=y", "auth");
        } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID); //Notify(kID,g_sAuthError, FALSE);
        if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sCommand == "public") {
        if (iNum==CMD_OWNER){
            g_iOpenAccess = TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "public=" + (string) g_iOpenAccess, "");
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Your %DEVICETYPE% is open to the public.",kID); 
            //Notify(kID, "Your " + g_sDeviceType + " is open to the public.", FALSE);
           // llRegionSayTo(g_kWearer, g_iInterfaceChannel, "CollarCommand|499|OwnerChange"); //tell attachments owner changed
        } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID); //Notify(kID,g_sAuthError, FALSE);
        if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sCommand == "private") {
        if (iNum==CMD_OWNER){
            g_iOpenAccess = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "public", "");
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Your %DEVICETYPE% is closed to the public.",kID); 
            //Notify(kID, "Your " + g_sDeviceType + " is closed to the public.", FALSE);
           // llRegionSayTo(g_kWearer, g_iInterfaceChannel, "CollarCommand|499|OwnerChange"); //tell attachments owner changed
        } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID); //Notify(kID,g_sAuthError, FALSE);
        if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (~llSubStringIndex(sCommand, "limitrange")) {
        if (sCommand == "limitrange") {
            if (iNum==CMD_OWNER){
                g_iLimitRange = TRUE;
                // as the default is range limit on, we do not need to store anything for this
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "limitrange", "");
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Public access range is limited.",kID);
                //Notify(kID, "Public access range is limited.", FALSE);
            } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID); //Notify(kID,g_sAuthError, FALSE);
            if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
        } else if (sCommand == "unlimitrange") {
            if (iNum==CMD_OWNER){
                g_iLimitRange = FALSE;
                // save off state for limited range (default is on)
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "limitrange=" + (string) g_iLimitRange, "");
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Public access range is simwide.",kID);
                //Notify(kID, "Public access range is simwide.", FALSE);
            } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID); //Notify(kID,g_sAuthError, FALSE);
            if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
        }
    } else if (sCommand == "runaway"){
        list lButtons=[];
        string message="Only the wearer or an Owner can access this menu";
       /* if (iNum == CMD_OWNER && kID == g_kWearer) {  //wearer-owner called for menu
            if (g_iRunawayDisable){
                lButtons=["Stay","Enable"];
                message="\nYou chose to disable the runaway function.\n\nAs an owner you can restore this ability if desired.";
            } else {
                lButtons=["Runaway!", "Stay"];
                message="\nYou can run away from your owners or you can disable your ability to ever run from them.";
            }
        } else*/ if (kID == g_kWearer){  //wearer called for menu
            if (g_iRunawayDisable){
                lButtons=["Stay","Cancel","Remain","Don't Run", "Stay Loyal"];
                message="\nACCESS DENIED:\n\nYou chose to disable the runaway function.\n\nOnly primary owners can restore this ability.";
            } else {
                lButtons=["Runaway!", "Stay"];
                message="\nYou can run away from your owners or you can stay with them.";
               // message="\nYou can run away from your owners or you can disable your ability to ever run from them.";
            }
        } else if (iNum == CMD_OWNER ) {  //owner called for menu
           /* if (g_iRunawayDisable){
                lButtons=["Release", "Enable"];
                message="\nYou can release this sub of your service or you can return their ability to run away on their own.";
            } else {*/
                lButtons=["Release"];
                message="\nYou can release this sub of your service.";
           // }
        }
        //Debug("runaway button");
        Dialog(kID, message, lButtons, [UPMENU], 0, iNum, "runawayMenu");
    } else if (~llSubStringIndex(sMessage,"runaway")) {
        if (sCommand == "enable") {
            if (iNum == CMD_OWNER) {
                g_iRunawayDisable = FALSE;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+"norun","");
                llMessageLinked(LINK_SET,NOTIFY,"0"+"The ability to runaway is enabled.",kID);
            } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID); 
        } else if (sCommand == "disable") {
            if (iNum == CMD_OWNER || iNum == CMD_WEARER) {
                g_iRunawayDisable = TRUE;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"norun=1","");
                llMessageLinked(LINK_SET,NOTIFY,"0"+"The ability to runaway is disabled.",kID);
            } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID); 
        }
    }
    return TRUE;
}

RunAway() {
    //llOwnerSay("Runaway initiated.");
    integer n;
    integer stop = llGetListLength(g_lOwners+g_lTempOwners);
    llMessageLinked(LINK_SET,NOTIFY_OWNERS,"%WEARERNAME% ran away!","");

    llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sSettingToken + "owner", "");
    llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sSettingToken + "tempowner", "");
    //llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sSettingToken + "trust=", "");
    //llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sSettingToken + "all", "");
    // moved reset request from settings to here to allow noticifation of owners.
    llMessageLinked(LINK_SET, CMD_OWNER, "clear", g_kWearer); // clear RLV restrictions
    llMessageLinked(LINK_SET, CMD_OWNER, "runaway", g_kWearer); // this is not a LM loop, since it is now really authed
    llMessageLinked(LINK_SET,NOTIFY,"0"+"Runaway finished.",g_kWearer);
    llResetScript();
}


default {
    on_rez(integer iParam) {
        llResetScript();
    }

    state_entry() {
      /*  if (g_iProfiled){
            llScriptProfiler(1);
           // Debug("profiling restarted");
        }*/
        //llSetMemoryLimit(65536);  
        g_kWearer = llGetOwner();  //until set otherwise, wearer is owner
        //Debug("Auth starting: "+(string)llGetFreeMemory());
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {  
        if (iNum == CMD_ZERO) { //authenticate messages on CMD_ZERO
            integer iAuth = Auth((string)kID, FALSE);
            if ( kID == g_kWearer && sStr == "runaway") {   // note that this will work *even* if the wearer is blacklisted or locked out
                if (g_iRunawayDisable){
                    llMessageLinked(LINK_SET,NOTIFY,"0"+"Runaway is currently disabled.",g_kWearer);
                } else {
                    UserCommand(iAuth,"runaway",kID, FALSE);
                }
            }
            else if (iAuth == CMD_OWNER && sStr == "runaway") { 
           // else if (kID != g_kWearer && iAuth == CMD_OWNER && sStr == "runaway") {  //owner requests the runaway menu
                //We trap here and pull up the UserCommand manually to avoid passing 'runaway' prematurely to linkmessage (this was unlocking/unleashing)
                UserCommand(iAuth, "runaway", kID, FALSE); 
            }
            else llMessageLinked(LINK_SET, iAuth, sStr, kID);

            //Debug("noauth: " + sStr + " from " + (string)kID + " who has auth " + (string)iAuth);
            return; // NOAUTH messages need go no further
        } else if (UserCommand(iNum, sStr, kID, FALSE)) return;
        else if (iNum == LM_SETTING_RESPONSE) {
            //Debug("Got setting response: "+sStr);
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sSettingToken) {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "owner") {
                    g_lOwners = llParseString2List(sValue, [","], []);
                } else if (sToken == "tempowner") {
                    g_lTempOwners = llParseString2List(sValue, [","], []);
                    //Debug("Tempowners: "+llDumpList2String(g_lTempOwners,","));
                } else if (sToken == "group") {
                    g_kGroup = (key)sValue;
                    //check to see if the object's group is set properly
                    if (g_kGroup != "") {
                        if ((key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0) == g_kGroup) g_iGroupEnabled = TRUE;
                        else g_iGroupEnabled = FALSE;
                    }
                    else g_iGroupEnabled = FALSE;
                }
                else if (sToken == "groupname") g_sGroupName = sValue;
                else if (sToken == "public") g_iOpenAccess = (integer)sValue;
                else if (sToken == "limitrange") g_iLimitRange = (integer)sValue;
                else if (sToken == "norun") g_iRunawayDisable = (integer)sValue;
                else if (sToken == "trust") g_lTrusted = llParseString2List(sValue, [","], [""]);
                else if (sToken == "block") g_lBlockList = llParseString2List(sValue, [","], [""]);
            } else if (llToLower(sStr) == "settings=sent") {
                if (llGetListLength(g_lOwners)) SayOwners();
            }
        }/* else if (iNum == LM_SETTING_EMPTY) {
            //Debug("Got setting empty: "+sStr);
            integer i = llSubStringIndex(sStr, "_");
            if (llGetSubString(sStr, 0, i) == g_sScript) {
                sStr = llGetSubString(sStr, i + 1, -1);
                if (sStr == "owner") {
                    g_lOwners = [];
                    SayOwners();
                } else if (sStr == "tempowner") {
                    g_lTempOwners = [];
                    //SayOwners();
                } else if (sStr == "group") {
                    g_kGroup = NULL_KEY;
                    g_iGroupEnabled = FALSE;
                }
                else if (sStr == "groupname") g_sGroupName = "";
                else if (sStr == "public") g_iOpenAccess = FALSE;
                else if (sStr == "limitrange") g_iLimitRange = TRUE;
                else if (sStr == "norun") g_iRunawayDisable = FALSE;
                else if (sStr == "trust") g_lTrusted = [];
                else if (sStr == "block") g_lBlockList = [];
            }
        }*/
    // JS: For backwards compatibility until all attachments/etc are rolled over to new interface
        //added for attachment auth (Garvin)
        else if (iNum == ATTACHMENT_REQUEST) {
          integer iAuth = Auth((string)kID, TRUE);
          llMessageLinked(LINK_SET, ATTACHMENT_RESPONSE, (string)iAuth+"|"+sStr, kID);
        }
    // JS: Remove ATTACHMENT_REQUEST & RESPONSE after all attachments have been updated properly
        else if (iNum == INTERFACE_REQUEST) {
            list lParams = llParseString2List(sStr, ["|"], []);
            string sTarget = llList2String(lParams, 0);
            string sCommand = llList2String(lParams, 1);
            if (sTarget == "auth_") {
                if (sCommand == "level") {
                    string sAuth = (string)Auth((string)kID, TRUE);
                    lParams = llListReplaceList(lParams, ["level=" + sAuth], 1, 1);
                }
                else return; // do not send response if the message was erroneous
                llMessageLinked(LINK_SET, INTERFACE_RESPONSE, llDumpList2String(lParams, "|"), kID);
            }
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
               
                //remove stride from g_lMenuIDs
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                
                
                if (sMenu == "Auth") {
                    //g_kAuthMenuID responds to setowner, setsecowner, setblacklist, remowner, remsecowner, remblacklist, setgroup, unsetgroup, setopenaccess, unsetopenaccess
                    if (sMessage == UPMENU) 
                        llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    else {
                        list lTranslation=[
                            "✚ Owner","owner",
//                            "✓ Temp Owner","tempowner",
                            "✚ Trusted","trust",
                            "✚ Blocked","block",
                            "♻ Owner","removeowner",
//                            "✗ Temp Owner","remtempowner",
                            "♻ Trusted","removetrust",
                            "♻ Blocked","removeblock",
                            "Group ☐","setgroup",
                            "Group ☒","unsetgroup",
                            "Public ☐","public",
                            "Public ☒","private",
                            "LimitRange ☐","limitrange",
                            "LimitRange ☒","unlimitrange",
                            //"Give Hud","givehud", 
                            "Access List","list",
                            "Runaway","runaway"
                        ];
                        integer buttonIndex=llListFindList(lTranslation,[sMessage]);
                        if (~buttonIndex){
                            sMessage=llList2String(lTranslation,buttonIndex+1);
                        }
                        //Debug("Sending UserCommand "+sMessage);
                        UserCommand(iAuth, sMessage, kAv, TRUE);
                    }
                } else if (sMenu == "removeowner" || sMenu == "removetrust" || sMenu == "removeblock" ) {
                    if (sMessage == UPMENU) {
                        AuthMenu(kAv, iAuth);
                    } else  if (sMessage == "Remove All") {
                        UserCommand(iAuth, sMenu + " Remove All", kAv,TRUE);
                    } else UserCommand(iAuth, sMenu+" " +sMessage, kAv, TRUE);
                    //as we get a key no need to check every single list for a name
                    /*else if (sMenu == "removeowner") {
                        UserCommand(iAuth, sMenu+" " + llList2String(g_lOwners, (integer)sMessage*2 - 1), kAv, TRUE);
                    } else if (sMenu == "remtempowner") {
                        UserCommand(iAuth, sMenu+" " + llList2String(g_lTempOwners, (integer)sMessage*2 - 1), kAv, TRUE);
                    } else if(sMenu == "removetrust") {
                        UserCommand(iAuth, sMenu+" " + llList2String(g_lTrusted, (integer)sMessage*2 - 1), kAv, TRUE);
                    } else if(sMenu == "removeblock") {
                        UserCommand(iAuth, sMenu+" " + llList2String(g_lBlockList, (integer)sMessage*2 - 1), kAv, TRUE);
                    }*/
                } else if (sMenu == "runawayMenu" ) {   //no chat commands for this menu, by design, so handle it all here
                    if (sMessage == UPMENU) {
                        AuthMenu(kAv, iAuth);
                    } else  if (sMessage == "Runaway!") {
                        //llMessageLinked(LINK_SET, CMD_ZERO, "runaway", kAv);
                        RunAway();
                    } else if (sMessage == "Cancel" || sMessage == "Stay") {
                        return;  //no remenu on canel
                    } else if (sMessage == "Release") {
                        integer iOwnerIndex=llListFindList(g_lOwners,[(string)kAv]);
                        if (~iOwnerIndex){
                            string name=llList2String(g_lOwners,iOwnerIndex+1);
                            UserCommand(iAuth, "removeowner "+name, kAv, FALSE);  //no remenu, owner is done with this sub
                            //llMessageLinked(LINK_SET, CMD_OWNER, "runaway", kID); //let other scripts know we're running away
                        } else {
                            llMessageLinked(LINK_SET,NOTIFY,"1"+"You are not on the access list.",kAv); 
                            UserCommand(iAuth,"runaway",kAv, TRUE); //remenu to runaway
                        }
                    } else { 
                        AuthMenu(kAv, iAuth);
                       // UserCommand(iAuth,"runaway",kAv, TRUE); //remenu to runaway
                    }
                }
            }
        } else if (iNum == FIND_AGENT) { //reply from add-by-name or add-from-menu (via FetchAvi dialog)
            if (kID == REQUEST_KEY) {
                list params = llParseString2List(sStr, ["|"], []);
                if (llList2String(params, 0) == g_sSettingToken) {
                    string sRequestType = llList2String(params, 4);
                    key kAv = llList2Key(params, 2);
                    integer iAuth = llList2Integer(params, 3);
                    key kNewOwner = (key)llList2String(params, 5);
                    if ((key)kNewOwner){
                        AddUniquePerson(kNewOwner, llKey2Name(kNewOwner), sRequestType, kAv); //should be safe to uase key2name here, as we added from sensor dialog
                        //FetchAvi(llList2Integer(params, 3), sRequestType, "", kAv);   //remenu
                        integer iNewAuth=Auth(kAv,FALSE);
                        if (iNewAuth == CMD_OWNER){
                            UserCommand(iNewAuth,sRequestType,kAv,TRUE);
                            //FetchAvi(CMD_OWNER, sRequestType, "", kAv);   //remenu
                        } else {
                            AuthMenu(kAv,iNewAuth);
                        }
                    } else if (llList2String(params, 5) == "BACK"){
                        AuthMenu(kAv,iAuth);
                    }
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            //remove stride from g_lMenuIDs
            //we have to subtract from the index because the dialog id comes in the middle of the stride
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                        
        }
    }

    http_response(key kQueryId, integer iStatus, list lMeta, string sBody) { //response to a group name lookup
        integer listIndex=llListFindList(g_lQueryId,[kQueryId]);
        if (listIndex!= -1){
            key g_kDialoger=llList2Key(g_lQueryId,listIndex+3);
            g_lQueryId=llDeleteSubList(g_lQueryId,listIndex,listIndex+g_iQueryStride-1);
            
            g_sGroupName = "(group name hidden)";
            if (iStatus == 200) {
                integer iPos = llSubStringIndex(sBody, "<title>");
                integer iPos2 = llSubStringIndex(sBody, "</title>");
                if ((~iPos) // Found
                    && iPos2 > iPos // Has to be after it
                    && iPos2 <= iPos + 43 // 36 characters max (that's 7+36 because <title> has 7)
                    && !~llSubStringIndex(sBody, "AccessDenied") // Check as per groupname.py (?)
                ) {
                    g_sGroupName = llGetSubString(sBody, iPos + 7, iPos2 - 1);
                }
            }
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Group set to " + g_sGroupName + ".",g_kDialoger);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "groupname=" + g_sGroupName, "");
        }
    }
    
    dataserver(key kQueryId, string sData){ //response after an add-by-uuid
        integer listIndex = llListFindList(g_lQueryId,[kQueryId]);
        if (listIndex!= -1){
            key newOwner = llList2Key(g_lQueryId,listIndex+1);
            string sRequestType = llList2String(g_lQueryId,listIndex+2);
            key kAv  =llList2Key(g_lQueryId,listIndex+3);
            integer iRemenu = llList2Integer(g_lQueryId,listIndex+4);
            
            g_lQueryId=llDeleteSubList(g_lQueryId,listIndex,listIndex+g_iQueryStride-1);
            
            AddUniquePerson(newOwner, sData, sRequestType, kAv);
            if (iRemenu){
                integer iNewAuth = Auth(kAv,FALSE);
                if (iNewAuth == CMD_OWNER){
                    UserCommand(iNewAuth,sRequestType,kAv,TRUE);
                    //FetchAvi(CMD_OWNER, sRequestType, "", kAv);   //remenu
                } else {
                    AuthMenu(kAv,iNewAuth);
                }
            }
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
/*
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/        
    }
}
