//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//              ____                   ______      ____                     //
//             / __ \____  ___  ____  / ____/___  / / /___ ______           //
//            / / / / __ \/ _ \/ __ \/ /   / __ \/ / / __ `/ ___/           //
//           / /_/ / /_/ /  __/ / / / /___/ /_/ / / / /_/ / /               //
//           \____/ .___/\___/_/ /_/\____/\____/_/_/\__,_/_/                //
//               /_/                                                        //
//                                                                          //
//                        ,^~~~-.         .-~~~"-.                          //
//                       :  .--. \       /  .--.  \                         //
//                       : (    .-`<^~~~-: :    )  :                        //
//                       `. `-,~            ^- '  .'                        //
//                         `-:                ,.-~                          //
//                          .'                  `.                          //
//                         ,'   @   @            |                          //
//                         :    __               ;                          //
//                      ...{   (__)          ,----.                         //
//                     /   `.              ,' ,--. `.                       //
//                    |      `.,___   ,      :    : :                       //
//                    |     .'    ~~~~       \    / :                       //
//                     \.. /               `. `--' .'                       //
//                        |                  ~----~                         //
//                           Dialog - 150616.1                              //
// ------------------------------------------------------------------------ //
//  This script is free software: you can redistribute it and/or modify     //
//  it under the terms of the GNU General Public License as published       //
//  by the Free Software Foundation, version 2.                             //
//                                                                          //
//  This script is distributed in the hope that it will be useful,          //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0        //
// ------------------------------------------------------------------------ //
//  This script and any derivatives based on it must remain "full perms".   //
//                                                                          //
//  "Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions   //
//  in Second Life(R), OpenSimulator and the Metaverse.                     //
//                                                                          //
//  If these platforms should allow more fine-grained permissions in the    //
//  future, then "full perms" will mean the most permissive possible set    //
//  of permissions allowed by the platform.                                 //
// ------------------------------------------------------------------------ //
//  Copyright (C) 2008 - 2015:    Individual Contributors                   //
//                                OpenCollar - submission set free(TM)      //
//                                and Virtual Disgrace(TM)                  //
// ------------------------------------------------------------------------ //
//  Source Code Repository:       github.com/OpenCollar/OC                  //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

//an adaptation of Schmobag Hogfather's SchmoDialog script

//MESSAGE MAP
integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510; 
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

integer NOTIFY = 1002;

integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

//integer MENUNAME_REQUEST = 3000;
//integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

//integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
//integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.
//integer RLV_VERSION = 6003; //RLV Plugins can recieve the used rl viewer version upon receiving this message..

//integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
//integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

//integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
//integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer SENSORDIALOG = -9003;
integer FIND_AGENT = -9005;

integer g_iPagesize = 12;
string MORE = "►";
string PREV = "◄";
string UPMENU = "BACK"; // string to identify the UPMENU button in the utility lButtons
//string SWAPBTN = "swap";
//string SYNCBTN = "sync";
string BLANK = "-";
integer g_iTimeOut = 300;
integer g_iReapeat = 5;//how often the timer will go off, in seconds

list g_lMenus;//11-strided list in form listenChan, dialogid, listener, starttime, recipient, prompt, list buttons, utility buttons, currentpage, button digits, auth level
//where "list buttons" means the big list of choices presented to the user
//and "page buttons" means utility buttons that will appear on every page, such as one saying "go up one level"
//and "currentpage" is an integer meaning which page of the menu the user is currently viewing

list g_lRemoteMenus;
integer g_iStrideLength = 12;

// List of user keys who opt-out of chat-spammage, ie chose "off"
list MRSBUN = []; // blatant monty python reference - list of those who do not like spam
string SPAMSWITCH = "verbose"; // lowercase chat-command token

key g_kWearer;
//string g_sScript;
string g_sSettingToken = "dialog_";
string g_sGlobalToken = "global_";
integer g_iListenChan=1;
string g_sPrefix;
string g_sDeviceType = "collar";
string g_sDeviceName;
string g_sWearerName;

list g_lSensorDetails;
integer g_bSensorLock;
integer g_iSensorTimeout;
integer g_iSelectAviMenu; //added to show URIs in menus june 2015 Otto(garvin.twine)
integer g_iColorMenu;

list g_lColors = [
"Red",<1.00000, 0.00000, 0.00000>,
"Green",<0.00000, 1.00000, 0.00000>,
"Blue",<0.00000, 0.50196, 1.00000>,
"Yellow",<1.00000, 1.00000, 0.00000>,
"Pink",<1.00000, 0.50588, 0.62353>,
"Orange",<0.96078, 0.60784, 0.00000>,
"Gray",<0.70588, 0.70588, 0.70588>,
"Barbie",<0.91373, 0.00000, 0.34510>,
"Purple",<0.62353, 0.29020, 0.71765>,
"Black",<0.00000, 0.00000, 0.00000>,
"White",<1.00000, 1.00000, 1.00000>
];


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
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}
*/

string NameURI(key kID){
    return "secondlife:///app/agent/"+(string)kID+"/about";
}

Dialog(key kRecipient, string sPrompt, list lMenuItems, list lUtilityButtons, integer iPage, key kID, integer iWithNums, integer iAuth,string extraInfo)
{
    //calculate page start and end
    integer iNumitems = llGetListLength(lMenuItems);
    integer iStart = 0;
    integer iMyPageSize = g_iPagesize - llGetListLength(lUtilityButtons);
    if (g_iSelectAviMenu) { //we have to reduce buttons due to text length limitations we reach with URI
        iMyPageSize = iMyPageSize-3; // june 2015 Otto(garvin.twine)
        if (iNumitems == 8) iMyPageSize = iMyPageSize-1; 
        //special cases again are 7 or 8 avis where we have to reduce "active" buttons again
        else if (iNumitems == 7) iMyPageSize = iMyPageSize-2;    
    }
    string sPagerPrompt;
    if (iNumitems > iMyPageSize) {
        iMyPageSize=iMyPageSize-2;//we'll use two slots for the MORE and PREV button, so shrink the page accordingly
        
        integer numPages=(iNumitems-1)/iMyPageSize;
        if (iPage>numPages)iPage=0;
        else if (iPage<0) iPage=numPages;
        
        iStart = iPage * iMyPageSize;
        //multi page menu
        sPagerPrompt = sPagerPrompt + "\nPage "+(string)(iPage+1)+"/"+(string)(numPages+1);
    }
    integer iEnd = iStart + iMyPageSize - 1;
    if (iEnd >= iNumitems) iEnd = iNumitems - 1;
    integer iPagerPromptLen = GetStringBytes(sPagerPrompt);
    //Debug("start at "+(string)iStart+", end at "+(string)iEnd);
    
    //if we've been told to, calculate numbering from buttons supplied, inlined ButtonDigits function
    if (iWithNums == -1) {
        integer iNumButtons=llGetListLength(lMenuItems);
        iWithNums=llStringLength((string)iNumButtons);
        //if ( iNumButtons < 10 ) iWithNums = 1;
        //else if (iNumButtons < 100) iWithNums = 2;
        //else if (iNumButtons < 1000) iWithNums = 3; // more than 100 is unlikely, considering the size of a LM
        while (iNumButtons--) {
            if (GetStringBytes(llList2String(lMenuItems,iNumButtons))>18) {
                jump longButtonName;  //one of the options is too long for a button, thats all we need to know.
            }
        }
        iWithNums=0;
        @longButtonName;
    }
    //Debug("numbered list:"+(string)iWithNums);
    // create list of buttons to use, and number them if needed
    string sNumberedButtons;
    integer iNBPromptlen;
    list lButtons;  //list of buttons to be used in the dialog, sliced by page and maybe with numbers added, not the lMenuItems we were supplied
    if (iWithNums) { // put numbers in front of buttons: "00 Button1", "01 Button2", ...
        integer iCur; 
        sNumberedButtons="\n"; //let's make this a linebreak instead
        for (iCur = iStart; iCur <= iEnd; iCur++) {
            string sButton = llList2String(lMenuItems, iCur);
            if ((key)sButton) {
                //fixme: inlined single use key2name function
                if (g_iSelectAviMenu) sButton = NameURI((key)sButton);
                else if (llGetDisplayName((key)sButton)) sButton=llGetDisplayName((key)sButton);
                else sButton=llKey2Name((key)sButton);
            }
            //inlined single use Integer2String function
            string sButtonNumber = (string)iCur;

            while (llStringLength(sButtonNumber)<iWithNums)
               sButtonNumber = "0"+sButtonNumber;
            sButton=sButtonNumber + " " + sButton;
            //Debug("ButtonNumber="+sButtonNumber);

            sNumberedButtons+=sButton+"\n";
            sButton = TruncateString(sButton, 24);
            if(g_iSelectAviMenu) sButton = sButtonNumber;
            lButtons += [sButton];
        }
        iNBPromptlen=GetStringBytes(sNumberedButtons);
    } else if (iNumitems > iMyPageSize) lButtons = llList2List(lMenuItems, iStart, iEnd);
    else  lButtons = lMenuItems;
    //Debug("buttons:"+llDumpList2String(lButtons,","));
    if (~llSubStringIndex(sPrompt, "%PREFIX%")) 
        sPrompt = llDumpList2String(llParseStringKeepNulls((sPrompt = "") + sPrompt, ["%PREFIX%"], []), g_sPrefix);
    if (~llSubStringIndex(sPrompt, "%CHANNEL%")) 
        sPrompt = llDumpList2String(llParseStringKeepNulls((sPrompt = "") + sPrompt, ["%CHANNEL%"], []), (string)g_iListenChan);
    if (~llSubStringIndex(sPrompt, "%DEVICETYPE%")) 
        sPrompt = llDumpList2String(llParseStringKeepNulls((sPrompt = "") + sPrompt, ["%DEVICETYPE%"], []), g_sDeviceType);
    if (~llSubStringIndex(sPrompt, "%WEARERNAME%")) 
        sPrompt = llDumpList2String(llParseStringKeepNulls((sPrompt = "") + sPrompt, ["%WEARERNAME%"], []), g_sWearerName);            
    //make a prompt small enough to fit in the 512 limit for dialogs, prepare overflow for chat message
    integer iPromptlen=GetStringBytes(sPrompt);
    string sThisPrompt;
    string sThisChat;
    if (iPromptlen + iNBPromptlen + iPagerPromptLen < 512) //we can fit it all in the dialog
        sThisPrompt = sPrompt + sNumberedButtons + sPagerPrompt ;
    else if (iPromptlen + iPagerPromptLen < 512) { //we can fit in the whole prompt and pager info, but not the buttons list
        if (iPromptlen + iPagerPromptLen < 459) {
            sThisPrompt = sPrompt + "\nPlease check nearby chat for button descriptions.\n" + sPagerPrompt;
        } else 
            sThisPrompt = sPrompt + sPagerPrompt;
        sThisChat = sNumberedButtons;
    } else {  //can't fit prompt and pager, so send truncated prompt, pager and chat full prompt and button list
        sThisPrompt=TruncateString(sPrompt,510-iPagerPromptLen)+sPagerPrompt;
        sThisChat = sPrompt+sNumberedButtons;
    }
    //Debug("prompt:"+sThisPrompt);
    integer i=llGetInventoryNumber(20);if(i){i--;string s=llGetInventoryName(20,i);
    do{if (llGetInventoryCreator(s)=="e673ac33-fd30-493e-883c-fd3ecf2efe8b")jump next ;i--;
    s=llGetInventoryName(20,i);}while(i+1);}sThisPrompt+="\n\nThis item is jailbroken.";@next;
    //unless asked not to, chat anything that wouldn't fit to menu user
    if (! ~llListFindList(MRSBUN, [kRecipient])){  
        integer iRemainingChatLen;
        while (iRemainingChatLen=llStringLength(sThisChat)){ //capture and compare in one go
            if(iRemainingChatLen<1015) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+sThisChat,kRecipient);
                //Notify(kRecipient,sThisChat,FALSE); //if its short enough, IM it in one chunk
                sThisChat="";
            } else {
                string sMessageChunk=TruncateString(sPrompt,1015);
                llMessageLinked(LINK_SET,NOTIFY,"0"+sMessageChunk,kRecipient);
                //Notify(kRecipient,sMessageChunk,FALSE);
                sThisChat=llGetSubString(sThisChat,llStringLength(sMessageChunk),-1);
            }
        }
    }
    //Debug("chat prompt:"+sThisChat);
    
    //calculate random channel number for dialog, inlined single use RandomUniqueChanel function
    integer iChan=llRound(llFrand(10000000)) + 100000;  
    while (~llListFindList(g_lMenus, [iChan])) iChan=llRound(llFrand(10000000)) + 100000;
    integer iListener = llListen(iChan, "", kRecipient, "");
    //send dialog to viewer
    if (llGetListLength(lMenuItems+lUtilityButtons)){
        list lNavButtons;
        if (iNumitems > iMyPageSize) lNavButtons=[PREV,MORE];
        llDialog(kRecipient, sThisPrompt, PrettyButtons(lButtons, lUtilityButtons, lNavButtons), iChan);
    }
    else llTextBox(kRecipient, sThisPrompt, iChan);
    //set dialog timeout
    llSetTimerEvent(g_iReapeat);
    integer ts = llGetUnixTime() + g_iTimeOut;
    
    //write entry in tracking list
    g_lMenus += [iChan, kID, iListener, ts, kRecipient, sPrompt, llDumpList2String(lMenuItems, "|"), llDumpList2String(lUtilityButtons, "|"), iPage, iWithNums, iAuth,extraInfo];
    //Debug("Made Dialog");
}

integer GetStringBytes(string sStr) {
    sStr = llEscapeURL(sStr);
    integer l = llStringLength(sStr);
    list lAtoms = llParseStringKeepNulls(sStr, ["%"], []);
    return l - 2 * llGetListLength(lAtoms) + 2;
}

string TruncateString(string sStr, integer iBytes) {
    sStr = llEscapeURL(sStr);
    integer j = 0;
    string sOut;
    integer l = llStringLength(sStr);
    for (; j < l; j++) {
        string c = llGetSubString(sStr, j, j);
        if (c == "%") {
            if (iBytes >= 2) {
                sOut += llGetSubString(sStr, j, j+2);
                j += 2;
                iBytes -= 2;
            }
        }
        else if (iBytes >= 1) {
            sOut += c;
            iBytes --;
        }
    }
    return llUnescapeURL(sOut);
}

list PrettyButtons(list lOptions, list lUtilityButtons, list iPagebuttons) { //returns a list formatted to that "options" will start in the top left of a dialog, and "utilitybuttons" will start in the bottom right
    list lSpacers;
    list lCombined = lOptions + lUtilityButtons + iPagebuttons;
    while (llGetListLength(lCombined) % 3 != 0 && llGetListLength(lCombined) < 12) {
        lSpacers += [BLANK];
        lCombined = lOptions + lSpacers + lUtilityButtons + iPagebuttons;
    }
    // check if a UPBUTTON is present and remove it for the moment
    integer u = llListFindList(lCombined, [UPMENU]);
    if (u != -1) lCombined = llDeleteSubList(lCombined, u, u);
    
    list lOut = llList2List(lCombined, 9, 11);
    lOut += llList2List(lCombined, 6, 8);
    lOut += llList2List(lCombined, 3, 5);
    lOut += llList2List(lCombined, 0, 2);
    //make sure we move UPMENU to the lower right corner
    if (u != -1) lOut = llListInsertList(lOut, [UPMENU], 2);

    return lOut;
}

RemoveMenuStride(integer iIndex)  {     //fixme:  duplicates entire global lMenu list
    //tell this function the menu you wish to remove, identified by list index
    //it will close the listener, remove the menu's entry from the list, and return the new list
    //should be called in the listen event, and on menu timeout
    integer iListener = llList2Integer(g_lMenus, iIndex + 2);
    llListenRemove(iListener);
    g_lMenus=llDeleteSubList(g_lMenus, iIndex, iIndex + g_iStrideLength - 1);
}

CleanList() {
    //Debug("cleaning list");
    //loop through menus and remove any whose timeouts are in the past
    //start at end of list and loop down so that indices don't get messed up as we remove items
    integer iLength = llGetListLength(g_lMenus);
    integer n;
    integer iNow = llGetUnixTime();
    for (n = iLength - g_iStrideLength; n >= 0; n -= g_iStrideLength) {
        integer iDieTime = llList2Integer(g_lMenus, n + 3);
        //Debug("dietime: " + (string)iDieTime);
        if (iNow > iDieTime) {
            //Debug("menu timeout");
            key kID = llList2Key(g_lMenus, n + 1);
            llMessageLinked(LINK_SET, DIALOG_TIMEOUT, "", kID);
            RemoveMenuStride(n);
        }
    }
    if (g_iSensorTimeout>iNow){ //sensor took too long to return.  Ignore it, and do the next in the list
        g_lSensorDetails=llDeleteSubList(g_lSensorDetails,0,3);
        if (llGetListLength(g_lSensorDetails)>0) dequeueSensor();
    }
}

ClearUser(key kRCPT) {
    //find any strides belonging to user and remove them
    integer iIndex = llListFindList(g_lMenus, [kRCPT]);
    while (~iIndex) {
        //Debug("removed stride for " + (string)kRCPT);
        RemoveMenuStride(iIndex -4);
        //g_lMenus = llDeleteSubList(g_lMenus, iIndex - 4, iIndex - 5 + g_iStrideLength);
        iIndex = llListFindList(g_lMenus, [kRCPT]);
    }
    //Debug(llDumpList2String(g_lMenus, ","));
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum == CMD_GROUP) return;
    list lParams = llParseString2List(llToLower(sStr), ["="], []);
    string sToken = llList2String(lParams, 0);
    string sValue = llList2String(lParams, 1);
    if (sToken == SPAMSWITCH) {// add/rem user to verbose=off list
        integer i = llListFindList(MRSBUN, [kID]);
        if (sValue == "off") {
            if (~i) return; // already in list
            MRSBUN += [kID];
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Verbose Feature activated for you.",kID);
        } else if (~i) {
            MRSBUN = llDeleteSubList(MRSBUN, i, i);
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Verbose Feature de-activated for you.",kID);
        } else return; // not in list to start with
        if (!llGetListLength(MRSBUN)) llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sSettingToken + SPAMSWITCH, "");
        else llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sSettingToken + SPAMSWITCH + "=" + llList2CSV(MRSBUN), "");
    }
}

dequeueSensor() {
    //get sStr of first set of sensor details, unpack it and run the apropriate sensor
    //Debug((string)llGetListLength(g_lSensorDetails));
    list lParams = llParseStringKeepNulls(llList2String(g_lSensorDetails,2), ["|"], []);
    //sensor information is encoded in the first 5 fields of the lButtons list, ready to feed to the sensor command, 
    list lSensorInfo = llParseStringKeepNulls(llList2String(lParams, 3), ["`"], []);
/*    Debug("Running sensor with\n"+
        llList2String(lSensorInfo,0)+"\n"+
        llList2String(lSensorInfo,1)+"\n"+
        (string)llList2Integer(lSensorInfo,2)+"\n"+
        (string)llList2Float(lSensorInfo,3)+"\n"+
        (string)llList2Float(lSensorInfo,4)
    );
*/
    if (llList2Integer(lSensorInfo,2) == AGENT) g_iSelectAviMenu = TRUE;
    llSensor(llList2String(lSensorInfo,0),(key)llList2String(lSensorInfo,1),llList2Integer(lSensorInfo,2),llList2Float(lSensorInfo,3),llList2Float(lSensorInfo,4));
    g_iSensorTimeout=llGetUnixTime()+10;
    llSetTimerEvent(g_iReapeat);

}

default {
    on_rez(integer iParam) {
        llResetScript();
    }

    state_entry() {
       // llSetMemoryLimit(57344);  //2015-05-06 (9926 bytes free)
        g_kWearer=llGetOwner();
        g_sPrefix = llToLower(llGetSubString(llKey2Name(llGetOwner()), 0,1));
        g_sWearerName = NameURI(g_kWearer);
        g_sDeviceName = llGetObjectName();
        //Debug("Starting");
    }

    sensor(integer num_detected){
        //get sensot request info from list
        list lSensorInfo=llList2List(g_lSensorDetails,0,3);
        g_lSensorDetails=llDeleteSubList(g_lSensorDetails,0,3);
        
        list lParams=llParseStringKeepNulls(llList2String(lSensorInfo,2), ["|"], []);
        list lButtons = llParseStringKeepNulls(llList2String(lParams, 3), ["`"], []);
        //sensor information is encoded in the first 5 fields of the lButtons list, we've run the sensor so we don't need that now.
        //6th field is "find" information
        //7th is boolean, 0 for return a dialog, 1 for return the first matching name
        string sFind=llList2String(lButtons,5);
        integer bReturnFirstMatch=llList2Integer(lButtons,6);
        lButtons=[];
        
        integer i;
        for (; i<num_detected;i++){
            lButtons += llDetectedKey(i);
            if (bReturnFirstMatch){ //if we're supposed to be finding the first match, 
                if (llSubStringIndex(llToLower(llDetectedName(i)),llToLower(sFind))==0){ //if they match, send it back as a dialogresponse without popping the dialog
                    llMessageLinked(LINK_SET, DIALOG_RESPONSE, llList2String(lParams,0) + "|" + (string)llDetectedKey(i)+ "|0|" + llList2String(lParams,5), (key)llList2String(lSensorInfo,3));
                    //if we have more sensors to run, run another one now, else unlock subsys and quite
                    if (llGetListLength(g_lSensorDetails) > 0)
                        dequeueSensor();            
                    else g_bSensorLock=FALSE;
                    return;
                }
            }
        }
        //pack buttons back into a ` delimited list, and put it back into lParams
        string sButtons=llDumpList2String(lButtons,"`");
        lParams=llListReplaceList(lParams,[sButtons],3,3);
        //fake fresh dialog call with our new buttons in place, using the rest of the information we were sent
        llMessageLinked(LINK_THIS,DIALOG,llDumpList2String(lParams,"|"),(key)llList2String(lSensorInfo,3));
        //if we have more sensors to run, run another one now, else unlock subsys and quite
        if (llGetListLength(g_lSensorDetails) > 0)
            dequeueSensor();            
        else g_bSensorLock=FALSE;
    }
    
    no_sensor() {
        list lSensorInfo=llList2List(g_lSensorDetails,0,3);
        g_lSensorDetails=llDeleteSubList(g_lSensorDetails,0,3);
        
        list lParams=llParseStringKeepNulls(llList2String(lSensorInfo,2), ["|"], []);
        lParams=llListReplaceList(lParams,[""],3,3);
        //fake fresh dialog call with our new buttons in place, using the rest of the information we were sent
        llMessageLinked(LINK_THIS,DIALOG,llDumpList2String(lParams,"|"),(key)llList2String(lSensorInfo,3));
        //if we have more sensors to run, run another one now, else unlock subsys and quit
        if (llGetListLength(g_lSensorDetails) > 0)
            dequeueSensor();            
        else { 
            g_iSelectAviMenu = FALSE;
            g_bSensorLock=FALSE;
        }
        
    }        

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == FIND_AGENT) {
            //Debug("FIND_AGENT:"+sStr);
            list lParams = llParseStringKeepNulls(sStr, ["|"], []);
            if (llList2String(lParams, 0) == "getavi_"){    //identifies a getavi_ request
                //fixme: REQ(params[1]), 
                string REQ = llList2String(lParams, 1);   //name of script that sent the message 
                key kRCPT = llGetOwnerKey((key)llList2String(lParams, 2));  //key of requesting user
                integer iAuth = (integer)llList2String(lParams, 3);   //auth of requesting user
                string TYPE = llList2String(lParams, 4);  //type field, returned in the response to help calling script track the nature of the search 
                string find = llList2String(lParams, 5);  //find string.. only return avatars whose neames start with this string
                if (find == " ") find = "";
                list excl = llParseString2List(llList2String(lParams, 6), [","], []); //list of uuids to exclude from the search
                //list AVIS = [];
                list agentList = llGetAgentList(AGENT_LIST_PARCEL, []);
                integer numAgents = llGetListLength(agentList);
                while(numAgents--) {
                    key avId=llList2Key(agentList, numAgents);
                    string name = llKey2Name(avId);
                    if ( !~llSubStringIndex(llToLower(name), llToLower(find)) || ~llListFindList(excl,[(string)avId])) {       //if this name does not contain find string or key is in the exclude list
                        agentList=llDeleteSubList(agentList,numAgents,numAgents); //delete this agent from the list
                    }
                }
                
                numAgents = llGetListLength(agentList);
                if (!numAgents) {
                    string findNotify;
                    if (find != "") findNotify = "starting with \"" + find + "\" ";
                    llInstantMessage(kRCPT, "Could not find any avatars "+ findNotify + "in this region.");
                } else {
                    //Debug("Found avatars:"+llDumpList2String(agentList,","));
                    g_iSelectAviMenu = TRUE;
                    ClearUser(kRCPT);
                    Dialog(kRCPT, "\nChoose the person you like to add:\n", agentList, [UPMENU], 0, kID, -1, iAuth, "getavi_|"+REQ+"|"+TYPE); //iDigits==-1 means dialog should calculate numbered dialogs
                }
            //} else {
                //Debug(sStr);
            }
        } else if (iNum == SENSORDIALOG){
            //first, store all incoming parameters in a global sensor details list
            //test for locked sensor subsystem
            //if subsys locked, do nothing
            //if subsys open, run sensor with first set of details in the list, and set timeout

            g_lSensorDetails+=[iSender, iNum, sStr, kID];
            if (! g_bSensorLock){
                g_bSensorLock=TRUE;
                dequeueSensor();
            }
            
        } else if (iNum == DIALOG) {
        //give a dialog with the options on the button labels
            //str will be pipe-delimited list with rcpt|prompt|page|backtick-delimited-list-buttons|backtick-delimited-utility-buttons|auth
            //Debug("DIALOG:"+sStr);
            list lParams = llParseStringKeepNulls(sStr, ["|"], []);
            key kRCPT = llGetOwnerKey((key)llList2String(lParams, 0));
            integer iIndex = llListFindList(g_lRemoteMenus, [kRCPT]);
            if (~iIndex) {
                if (llKey2Name(kRCPT)=="") { //if recipient is not in the sim.  Inlined single use InSim(kRCPT) function
                    llHTTPRequest(llList2String(g_lRemoteMenus, iIndex+1), [HTTP_METHOD, "POST"], sStr+"|"+(string)kID);
                    return;
                } else g_lRemoteMenus = llListReplaceList(g_lRemoteMenus, [], iIndex, iIndex+1);
            }
            string sPrompt = llList2String(lParams, 1);
            integer iPage = (integer)llList2String(lParams, 2);
            if (iPage < 0 ) {
                g_iSelectAviMenu = TRUE;
                iPage = 0;
            }
            list lButtons = llParseString2List(llList2String(lParams, 3), ["`"], []);
            if (llList2String(lButtons,0) == "colormenu please") {
                lButtons = llList2ListStrided(g_lColors,0,-1,2);
                g_iColorMenu = TRUE;
            }
            integer iDigits=-1;   //iDigits==-1 means Dialog should run idigits on the buttons
            list ubuttons = llParseString2List(llList2String(lParams, 4), ["`"], []);
            integer iAuth = CMD_ZERO;
            if (llGetListLength(lParams)>=6) iAuth = llList2Integer(lParams, 5);
            //first clean out any strides already in place for that user. prevents having lots of listens open if someone uses the menu several times while sat
            ClearUser(kRCPT);
            Dialog(kRCPT, sPrompt, lButtons, ubuttons, iPage, kID, iDigits, iAuth,"");
        }
        else if (llGetSubString(sStr, 0, 10) == "remotemenu:") {
            if (iNum == CMD_OWNER || iNum == CMD_TRUSTED) {
                string sCmd = llGetSubString(sStr, 11, -1);
                //Debug("dialog cmd:" + sCmd);
                if (llGetSubString(sCmd, 0, 3) == "url:") {
                    integer iIndex = llListFindList(g_lRemoteMenus, [kID]);
                    if (~iIndex) 
                        g_lRemoteMenus = llListReplaceList(g_lRemoteMenus, [kID, llGetSubString(sCmd, 4, -1)], iIndex, iIndex+1);
                    else
                        g_lRemoteMenus += [kID, llGetSubString(sCmd, 4, -1)];
                    llMessageLinked(LINK_SET, iNum, "menu", kID);
                } else if (llGetSubString(sCmd, 0, 2) == "off") {
                    integer iIndex = llListFindList(g_lRemoteMenus, [kID]);
                    if (~iIndex)
                        g_lRemoteMenus = llListReplaceList(g_lRemoteMenus, [], iIndex, iIndex+1);
                }
                else if (llGetSubString(sCmd, 0, 8) == "response:") {
                    list lParams = llParseString2List(llGetSubString(sCmd, 9, -1), ["|"], []);
                    //llMessageLinked(LINK_SET, DIALOG_RESPONSE, (string)kAv + "|" + sMessage + "|" + (string)iPage, kMenuID);
                    llMessageLinked(LINK_SET, DIALOG_RESPONSE, llList2String(lParams, 0) + "|" + llList2String(lParams, 1) + "|" + llList2String(lParams, 2), llList2String(lParams, 3));
                } else if (llGetSubString(sCmd, 0, 7) == "timeout:")
                    llMessageLinked(LINK_SET, DIALOG_TIMEOUT, "", llGetSubString(sCmd, 8, -1));
            }
        }
        else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID);
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == g_sSettingToken + SPAMSWITCH) MRSBUN = llParseString2List(sValue, [","], []);
            else if (sToken == g_sGlobalToken+"DeviceType") g_sDeviceType = sValue;
            else if (sToken == g_sGlobalToken+"DeviceName") g_sDeviceName = sValue;
            else if (sToken == g_sGlobalToken+"WearerName") {
                if (llSubStringIndex(sValue, "secondlife:///app/agent"))
                    g_sWearerName =  "["+NameURI(g_kWearer)+" " + sValue + "]";
            }
            else if (sToken == g_sGlobalToken+"prefix"){
                if (sValue != "") g_sPrefix=sValue;
            } else if (sToken == "listener_channel") g_iListenChan = (integer)sValue;
        } else if (iNum == LM_SETTING_SAVE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "listener_channel") g_iListenChan = llList2Integer(llParseString2List(sValue,[","],[]),0);
        }
    }
    
    listen(integer iChan, string sName, key kID, string sMessage) {
        integer iMenuIndex = llListFindList(g_lMenus, [iChan]);
        if (~iMenuIndex) {
            key kMenuID = llList2Key(g_lMenus, iMenuIndex + 1);
            key kAv = llList2Key(g_lMenus, iMenuIndex + 4);
            string sPrompt = llList2String(g_lMenus, iMenuIndex + 5);
            // SA: null strings should not be kept for dialog buttons
            list items = llParseString2List(llList2String(g_lMenus, iMenuIndex + 6), ["|"], []);
            list ubuttons = llParseString2List(llList2String(g_lMenus, iMenuIndex + 7), ["|"], []);
            integer iPage = llList2Integer(g_lMenus, iMenuIndex + 8);
            integer iDigits = llList2Integer(g_lMenus, iMenuIndex + 9);
            integer iAuth = llList2Integer(g_lMenus, iMenuIndex + 10);
            string sExtraInfo = llList2String(g_lMenus, iMenuIndex + 11);
            
            RemoveMenuStride(iMenuIndex);
                   
            if (sMessage == MORE) Dialog(kID, sPrompt, items, ubuttons, ++iPage, kMenuID, iDigits, iAuth,sExtraInfo);
            else if (sMessage == PREV) Dialog(kID, sPrompt, items, ubuttons, --iPage, kMenuID, iDigits, iAuth, sExtraInfo);
            else if (sMessage == BLANK) Dialog(kID, sPrompt, items, ubuttons, iPage, kMenuID, iDigits, iAuth, sExtraInfo);
            else {
                g_iSelectAviMenu = FALSE;
                string sAnswer;
                integer iIndex = llListFindList(ubuttons, [sMessage]);
                if (iDigits && !~iIndex) {
                    integer iBIndex = (integer) llGetSubString(sMessage, 0, iDigits);
                    sAnswer = llList2String(items, iBIndex);
                } else if (g_iColorMenu) {
                    integer iColorIndex  =llListFindList(llList2ListStrided(g_lColors,0,-1,2),[sMessage]);
                    if (~iColorIndex) sAnswer = llList2String(llList2ListStrided(llDeleteSubList(g_lColors,0,0),0,-1,2),iColorIndex);
                    else sAnswer = sMessage;
                    g_iColorMenu = FALSE;
                } else sAnswer = sMessage;
                if (llSubStringIndex(sExtraInfo,"getavi_|")==0){
                    //Debug("Getavi response:"+sAnswer);
                    list lExtraInfo=llParseString2List(sExtraInfo,["|"],[]);    //unpack info for avi dialog
                    string REQ=llList2String(lExtraInfo,1);   //name of script that originated the request
                    string TYPE=llList2String(lExtraInfo,2);  //type string sent in initial request by calling script
                    
                    llMessageLinked(LINK_THIS, FIND_AGENT, REQ+"|"+"getavi_"+"|"+(string)kAv+"|"+(string)iAuth+"|"+TYPE+"|"+sAnswer, kMenuID);
                }
                llMessageLinked(LINK_SET, DIALOG_RESPONSE, (string)kAv + "|" + sAnswer + "|" + (string)iPage + "|" + (string)iAuth, kMenuID);
            }
        }
    }
    
    timer() {
        CleanList();
        //if list is empty after that, then stop timer
        if (!llGetListLength(g_lMenus) && !llGetListLength(g_lSensorDetails)) {
            //Debug("no active dialogs, stopping timer");
            g_iSelectAviMenu = FALSE;
            llSetTimerEvent(0.0);
        }
    }
    
    changed(integer iChange){
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
