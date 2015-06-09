////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            Virtual Disgrace - Spy                              //
//                                  version 1.8                                   //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
//        ©   2013 - 2014  Individual Collaborators and Virtual Disgrace™         //
// ------------------------------------------------------------------------------ //
//                       github.com/VirtualDisgrace/Collar                        //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// Based on the OpenCollar - subspy 3.957
// Compatible with OpenCollar API   3.9
// and/or minimum Disgraced Version 1.3.2

string g_sChatBuffer;  //if this has anything in it at end of interval, then tell owners (if listen enabled)

integer g_iListener;

integer g_iTraceEnabled=FALSE;
integer g_iListenEnabled=FALSE;
integer g_iNotifyEnabled=FALSE;

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER                   = 500;
//integer CMD_TRUSTED                 = 501;
//integer CMD_GROUP                 = 502;
integer CMD_WEARER                  = 503;
//integer CMD_EVERYONE                = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD                = 510; 
//integer CMD_RELAY_SAFEWORD          = 511;
//integer CMD_BLOCKED = 520;

//integer NOTIFY=1002; 
//integer NOTIFY_OWNERS=1003;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the httpdb

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

//string g_sScript = "subspy_";
string g_sSettingToken = "spy_";
string g_sGlobalToken = "global_";

string UPMENU = "BACK";

list g_lOwners;
list g_lTempOwners;
string g_sWearerName;
key g_kWearer;
string g_sDeviceName;

key g_kDialogSpyID;
integer serial;

/*
integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to 
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+") :\n" + sStr);
}
*/

DoReports(string sChatLine, integer sendNow, integer fromTimer) {
    if (!(g_iTraceEnabled||g_iListenEnabled)) return;
    
    integer iMessageLimit=500;
    //store chat
    if (g_iListenEnabled && sChatLine != "") {
        g_sChatBuffer += sChatLine+"\n";
    }

    string sLocation;
    if (g_iTraceEnabled) {
        vector vPos=llGetPos();
        string sRegionName=llGetRegionName();
        //sLocation += " %g_sWearerName% is at http://maps.secondlife.com/secondlife/"+ llEscapeURL(sRegionName)+ "/"+ (string)llFloor(vPos.x)+ "/"+(string)llFloor(vPos.y)+"/"+(string)llFloor(vPos.z);
        sLocation += " "+g_sWearerName+" is at http://maps.secondlife.com/secondlife/"+llEscapeURL(sRegionName)+"/"+(string)llFloor(vPos.x)+"/"+(string)llFloor(vPos.y)+"/"+(string)llFloor(vPos.z);
    }
    string sHeader="["+(string)serial + "]"+sLocation+"\n";
    
    integer iMessageLength=llStringLength(sHeader)+llStringLength(g_sChatBuffer);
    if (iMessageLength > iMessageLimit || (g_sChatBuffer!="" && fromTimer) || sendNow) { //if we have too much chat, or the timer fired and we have something to report, or we got a sendnow
        //Debug("Sending report");
        while (iMessageLength > iMessageLimit){
            g_sChatBuffer=sHeader+g_sChatBuffer;
            iMessageLength=llStringLength(g_sChatBuffer);
            //Debug("message length:"+(string)iMessageLength);
            //Debug("header length:"+(string)llStringLength(sHeader));
            integer index=iMessageLimit;
            while (llGetSubString(g_sChatBuffer,index,index) != "\n"){
                index--;
            }
            //Debug("Found a return at "+(string) index);
            if (index <= llStringLength(sHeader)){
                index=iMessageLimit;
                while (llGetSubString(g_sChatBuffer,index,index) != " "){
                    index--;
                }
                if (index <= llStringLength(sHeader)) {
                    index=iMessageLimit;
                    //Debug("Found no breaks, breaking at "+(string) index);
                //} else {
                    //Debug("Found a space at "+(string) index);
                }
            }
            string sMessageToSend=llGetSubString(g_sChatBuffer,0,index);
            //Debug("send length:"+(string)llStringLength(sMessageToSend));
            NotifyOwners(sMessageToSend);
            serial++;
            sHeader="["+(string)serial + "]\n";
            
            g_sChatBuffer=llGetSubString(g_sChatBuffer,index+1,-1);
            iMessageLength=llStringLength(sHeader)+llStringLength(g_sChatBuffer);
            //Debug("remaining:"+(string)iMessageLength);
        }
        if (sendNow || fromTimer){
            sHeader="["+(string)serial + "]"+sLocation+"\n";
            NotifyOwners(sHeader+g_sChatBuffer);
            serial++;
            g_sChatBuffer="";
            //Debug("Emptied buffer");
        }

        //make a warning for the user
        if (g_iNotifyEnabled){
            
        string activityWarning="\n\nThe Spy app is reporting your ";
        if (g_iTraceEnabled) activityWarning += "location ";
        if (g_iTraceEnabled && g_iListenEnabled)  activityWarning += "and ";
        if (g_iListenEnabled)  activityWarning += "chat activity ";
        activityWarning += "to your primary owners.\n";
        Notify(g_kWearer,activityWarning,FALSE);
            
        }        
    } else {
        return;
    }
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

DialogSpy(key kID, integer iAuth) {
    string sPrompt="\n[http://www.virtualdisgrace.com/spy Virtual Disgrace - Spy]";
    
    list lButtons ;

    if(g_iTraceEnabled) lButtons += ["☒ Trace"];
    else lButtons += ["☐ Trace"];
    
    if (g_iListenEnabled) lButtons += ["☒ Listen"];
    else lButtons += ["☐ Listen"];

    g_kDialogSpyID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer){
    string sObjectName = llGetObjectName();
    if (g_sDeviceName != sObjectName) llSetObjectName(g_sDeviceName);
    if (kID == g_kWearer) {
        while (llStringLength(sMsg)>1000){
            string sSendString=llGetSubString(sMsg,0,1000);
            llOwnerSay(sSendString);
            sMsg=llGetSubString(sMsg,1001,-1);
        }
        llOwnerSay(sMsg);
    } else {
        //Debug("Notifying "+(string)kID);
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
    llSetObjectName(sObjectName);
}

NotifyOwners(string sMsg) {
    integer n;
    integer iStop = llGetListLength(g_lOwners+g_lTempOwners);
    for (n = 0; n < iStop; n += 2) {
        key kAv = (key)llList2String(g_lOwners+g_lTempOwners, n);
        //we don't want to bother the owner if he/she is right there, so check distance
        vector vOwnerPos = (vector)llList2String(llGetObjectDetails(kAv, [OBJECT_POS]), 0);
        if (vOwnerPos == ZERO_VECTOR || llVecDist(vOwnerPos, llGetPos()) > 20.0) {//vOwnerPos will be ZERO_VECTOR if not in sim
            //Debug("notifying " + (string)kAv);
            Notify(kAv, sMsg,FALSE);
        }
    }
}

UserCommand (integer iAuth, string sStr, key kID, integer remenu) {
    sStr = llToLower(sStr);
        if (sStr == "☐ trace" || sStr == "trace on") {
            if (kID==g_kWearer) {
                if (!g_iTraceEnabled) {
                    g_iTraceEnabled=TRUE;
                    Notify(kID,"\n\nTrace enabled.\n",TRUE);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"trace=1", "");
                }
            } else {
                Notify(kID,"\n\nOnly the wearer may enable spy functions.\n",TRUE);
            }
            if (remenu) DialogSpy(kID,iAuth);
        } else if(sStr == "☒ trace" || sStr == "trace off") {
            if (iAuth == CMD_OWNER) {
                if (g_iTraceEnabled){
                    g_iTraceEnabled=FALSE;
                    Notify(kID,"\n\nTrace disabled.\n",TRUE);
                    llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+"trace", "");
                }
            } else {
                Notify(kID,"\n\nOnly an owner may disable spy functions.\n",TRUE);
            }
            if (remenu) DialogSpy(kID,iAuth);
        } else if(sStr == "☐ listen" || sStr == "listen on") {
            if (kID==g_kWearer) {
                if (!g_iListenEnabled) {
                    g_iListenEnabled=TRUE;
                    Notify(kID,"\n\nChat Spy enabled.\n",TRUE);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"listen=1", "");
                    llListenRemove(g_iListener);
                    g_iListener = llListen(0, "", g_kWearer, "");
                }
            } else {
                Notify(kID,"\n\nOnly the wearer may enable spy functions.\n",TRUE);
            }
            if (remenu) DialogSpy(kID,iAuth);
        } else if(sStr == "☒ listen" || sStr == "listen off") {
            if (iAuth == CMD_OWNER) {
                if (g_iListenEnabled) {
                    g_iListenEnabled=FALSE;
                    Notify(kID,"\n\nChat Spy disabled.\n",TRUE);
                    llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+"listen", "");
                    llListenRemove(g_iListener);
                    g_iListener = 0;
                }
            } else {
                Notify(kID,"\n\nOnly an owner may disable spy functions.\n",TRUE);
            }
            if (remenu) DialogSpy(kID,iAuth);
        } else if (sStr == "☐ notify" || sStr == "spynotify on") {
            if (kID==g_kWearer) {
                if (!g_iNotifyEnabled) {
                    g_iNotifyEnabled=TRUE;
                    Notify(kID,"\n\nSpy notifications enabled.\n",TRUE);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"notify=1", "");
                }
            } else {
                Notify(kID,"\n\nOnly the wearer may enable spy notifications.\n",TRUE);
            }
            if (remenu) DialogSpy(kID,iAuth);
        } else if (sStr == "☒ notify" || sStr == "spynotify off") {
            if (kID==g_kWearer) {
                if (g_iNotifyEnabled){
                    g_iNotifyEnabled=FALSE;
                    Notify(kID,"\n\nSpy notifications disabled.\n",TRUE);
                    llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+"notify", "");
                }
            } else {
                Notify(kID,"\n\nOnly the wearer may enable spy notifications.\n",TRUE);
            }
            if (remenu) DialogSpy(kID,iAuth);
        } else if ("runaway" == sStr) {
            g_iListenEnabled=FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+"listen", "");
            llListenRemove(g_iListener);
            g_iListener = 0;

            g_lOwners = [];
            g_lTempOwners = [];
            
            g_iTraceEnabled=FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+"trace", "");
            
            g_iNotifyEnabled=FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+"notify", "");
        } else if (sStr == "spy" || sStr == "menu spy") DialogSpy(kID, iAuth);
}

default {
    state_entry() {
        llSetMemoryLimit(32768);  //2015-05-06 (6622 bytes free)
        g_kWearer = llGetOwner();
        g_sDeviceName = llGetObjectName();
        g_sWearerName = "secondlife:///app/agent/"+(string)g_kWearer+"/about";
        g_lOwners = [g_kWearer, llKey2Name(g_kWearer)];  // initially self-owned until we hear a db message otherwise
        llSetTimerEvent(300);
        //Debug("Starting");
    }

    listen(integer channel, string sName, key kID, string sMessage) {
        if(kID == g_kWearer && channel == 0) {
            //process emotes, replace with sub name
            //if(llGetSubString(sMessage, 0, 3) == "/me ") sMessage="%g_sWearerName%" + llGetSubString(sMessage, 3, -1);
            if(llGetSubString(sMessage, 0, 3) == "/me ") sMessage=g_sWearerName + llGetSubString(sMessage, 3, -1);
            //else sMessage="%g_sWearerName%: " + sMessage;
            else sMessage=g_sWearerName+": " + sMessage;
            DoReports(sMessage,FALSE,FALSE);
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID, FALSE);
        else if (iNum == LM_SETTING_DELETE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            if(sToken == "auth_owner") g_lOwners = [];
            else if(sToken == "auth_tempowner") g_lTempOwners = [];
        } else if (iNum == LM_SETTING_SAVE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if(sToken == "auth_owner" && llStringLength(sValue) > 0) g_lOwners = llParseString2List(sValue, [","], []);
            else if(sToken == "auth_tempowner" && llStringLength(sValue) > 0) g_lTempOwners = llParseString2List(sValue, [","], []);
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);

            if (llSubStringIndex(sToken, g_sSettingToken+"")==0) { //spy data
                if (sToken == g_sSettingToken+"trace") {
                    if (!g_iTraceEnabled) {
                        g_iTraceEnabled=TRUE;
                        Notify(g_kWearer,"\n\nTrace enabled.\n",FALSE);
                    }
                } else if (sToken == g_sSettingToken+"notify") {
                    if (!g_iNotifyEnabled) {
                        g_iNotifyEnabled=TRUE;
                        Notify(g_kWearer,"\n\nNotifications enabled.\n",FALSE);
                    }
                } else if (sToken == g_sSettingToken+"listen") {
                    if (!g_iListenEnabled) {
                        g_iListenEnabled=TRUE;
                        Notify(g_kWearer,"\n\nChat Spy enabled.\n",FALSE);
                        llListenRemove(g_iListener);
                        g_iListener = llListen(0, "", g_kWearer, "");
                    }
                }
            } else if (sToken == g_sGlobalToken+"DeviceName") g_sDeviceName = sValue;
            else if (sToken == g_sGlobalToken+"WearerName") {
                if (llSubStringIndex(sValue, "secondlife:///app/agent"))
                    g_sWearerName =  "[secondlife:///app/agent/"+(string)g_kWearer+"/about " + sValue + "]";
            }
            else if(sToken == "auth_owner" && llStringLength(sValue) > 0) g_lOwners = llParseString2List(sValue, [","], []); //owners list
            else if(sToken == "auth_tempowner" && llStringLength(sValue) > 0) g_lTempOwners = llParseString2List(sValue, [","], []); //tempowners list
        } else if (iNum == MENUNAME_REQUEST && sStr == "Apps") {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, "Apps|Spy", "");
        } else if (iNum == DIALOG_RESPONSE) {
            if (kID == g_kDialogSpyID) { //settings change from main spy
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iAuth = (integer)llList2String(lMenuParams, 3);

                if (sMessage == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu apps", kAv);
                else UserCommand(iAuth, sMessage, kAv, TRUE);
            }
        }
    }

    timer (){
        DoReports("",FALSE,TRUE);
    }

    attach(key kID) {
        if (kID) DoReports("",TRUE, FALSE);
    }

    changed(integer iChange) {
        if (iChange & CHANGED_REGION) DoReports("",TRUE,FALSE);
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
