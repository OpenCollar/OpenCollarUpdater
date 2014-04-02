////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                               OpenCollar - main                                //
//                                 version 3.958                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//on start, send request for submenu names
//on getting submenu name, add to list if not already present
//on menu request, give dialog, with alphabetized list of submenus
//on listen, send submenu link message

string g_sCollarVersion="(loading...)";
integer g_iLatestVersion=TRUE;

list g_lOwners;
key g_kWearer;

list g_lMenuNames = ["Main", "Apps", "Help/About"];
list g_lMenus;//exists in parallel to g_lMenuNames, each entry containing a pipe-delimited string with the items for the corresponding menu
list g_lMenuPrompts;

list g_lMenuIDs;//3-strided list of avatars given menus, their dialog ids, and the name of the menu they were given
integer g_iMenuStride = 3;

//integer g_iListenChan = 1908789;
//integer g_iListener;
//integer g_iTimeOut = 60;

integer g_iScriptCount;//when the scriptcount changes, rebuild menus

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
                            //str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the httpdb

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

//5000 block is reserved for IM slaves

string UPMENU = "BACK";
//string MORE = ">";
string GIVECARD = "Quick Guide";
string HELPCARD = "OpenCollar Guide";
//string REFRESH_MENU = "Fix Menus";
string DEV_GROUP = "Join R&D";
string USER_GROUP = "Join Support";
string BUGS="Report Bug";
string DEV_GROUP_ID = "c5e0525c-29a9-3b66-e302-34fe1bc1bd43";
string USER_GROUP_ID = "0f6f3627-d9cb-a1db-b770-f66fce70d1ef";
//string UPDATE="Get Update";
string WIKI = "Website";
string WIKI_URL = "http://www.opencollar.at/";
string BUGS_URL = "http://www.opencollar.at/forum.html#!/support";
string LICENSECARD="OpenCollar License";
string LICENSE="License";
//string SETTINGSHELP="Settings Help";
//string SETTINGSHELP_URL="http://www.opencollar.at/";

integer g_iLocked = FALSE;
integer g_bDetached = FALSE;
integer g_iHide ; // global hide

string g_sLockPrimName="Lock"; // Description for lock elements to recognize them //EB //SA: to be removed eventually (kept for compatibility)
string g_sOpenLockPrimName="OpenLock"; // Prim description of elements that should be shown when unlocked
string g_sClosedLockPrimName="ClosedLock"; // Prim description of elements that should be shown when locked
list g_lClosedLockElements; //to store the locks prim to hide or show //EB
list g_lOpenLockElements; //to store the locks prim to hide or show //EB

string LOCK = "LOCK";
string UNLOCK = "UNLOCK";
string CTYPE="collar";
string g_sDefaultLockSound="caa78697-8493-ead3-4737-76dcc926df30";
string g_sDefaultUnlockSound="ff09cab4-3358-326e-6426-ec8d3cd3b98e";
string g_sLockSound="caa78697-8493-ead3-4737-76dcc926df30";
string g_sUnlockSound="ff09cab4-3358-326e-6426-ec8d3cd3b98e";

//Debug(string text){llOwnerSay(llGetScriptName() + ": " + text);}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer)
    {
        llOwnerSay(sMsg);
    }
    else
    {
        llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer)
        {
            llOwnerSay(sMsg);
        }
    }
}

Menu(string sName, key kID, integer iAuth)
{
    integer iMenuIndex = llListFindList(g_lMenuNames, [sName]);
    //Debug((string)iMenuIndex);    
    if (iMenuIndex != -1)
    {
        list lItems = llParseString2List(llList2String(g_lMenus, iMenuIndex), ["|"], []);

        string sPrompt = GetPrompt(iMenuIndex);
        
        list lUtility = [];
        
        key kMenuID;
        if (sName != "Main")
        {
            lUtility = [UPMENU];
            kMenuID = Dialog(kID, sPrompt, lItems, lUtility, 0, iAuth);
        } else {    //it's the main menu, show the right lock button
            if (g_iLocked){
                kMenuID = Dialog(kID, sPrompt, UNLOCK+lItems, lUtility, 0, iAuth);
            } else {
                kMenuID = Dialog(kID, sPrompt, LOCK+lItems, lUtility, 0, iAuth);
            }
        }
        
        
        integer iIndex = llListFindList(g_lMenuIDs, [kID]);
        if (~iIndex)
        {
            //we've alread given a menu to this user.  overwrite their entry
            g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
        }
        else
        {
            //we've not already given this user a menu. append to list
            g_lMenuIDs += [kID, kMenuID, sName];
        }
    }
}

integer KeyIsAv(key kID)
{
    return llGetAgentSize(kID) != ZERO_VECTOR;
}

string GetPrompt(integer index) //return prompt for menu, index of g_lMenuNames
{
    if(index==0) return "\n\nWelcome to the Main Menu\nOpenCollar Version "+g_sCollarVersion; //main
    else if (index==1) return "\n\nThis menu grants access to features of Add-on scripts.\n"; //add-ons
    else //help/about
    {
        string sTemp="\nOpenCollar version "+g_sCollarVersion+"\n";
        if(!g_iLatestVersion) sTemp+="Update available!";
        return sTemp + "\n\nThe OpenCollar stock software bundle in this item is licensed under the GPLv2 with additional requirements specific to Second Life®.\n\n© 2008 - 2014 Individual Contributors and\nOpenCollar - submission set free™\n";
//moved to bugs button response
// \n\nPlease help us make things better and report bugs here:\n\nhttp://www.opencollar.at/forum.html#!/support\nhttps://github.com/OpenCollar/OpenCollarUpdater/issues\n\n(Creating a moot.it or github account is quick, simple, free and won't up your privacy. Forums could be fun.)";
    }
}
    
MenuInit()
{
//list g_lMenuNames = ["Main", "Apps", "Help/About"];
    g_lMenus = ["Apps|Animations|Appearance|Leash|RLV|Access|Options|Help/About","",WIKI+"|"+GIVECARD+"|"+DEV_GROUP+"|"+USER_GROUP+"|"+BUGS+"|"+LICENSE+"|"+"Update"+"|"+"Get Updater"];

    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Main", ""); 
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "AddOns", "");
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Apps", "");
    //llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Help/About", ""); 
}

HandleMenuResponse(string entry)
{
    //entry will be in form of "parent|menuname"
    list lParams = llParseString2List(entry, ["|"], []);
    string sName = llList2String(lParams, 0);
    
    if (sName=="AddOns" || sName=="Apps"){  //we only accept buttons for apps nemu
        //Debug("we handle " + sName);
        string sSubMenu = llList2String(lParams, 1);
        list lGuts = llParseString2List(llList2String(g_lMenus, 1), ["|"], []);
        if (llListFindList(lGuts, [sSubMenu]) == -1)
        {
            lGuts += [sSubMenu];
            lGuts = llListSort(lGuts, 1, TRUE);
            g_lMenus = llListReplaceList(g_lMenus, [llDumpList2String(lGuts, "|")], 1, 1);
        }
    }
}

HandleMenuRemove(string entry)
{
    //entry will be in form of "parent|menuname"
    list lParams = llParseString2List(entry, ["|"], []);
    string sName = llList2String(lParams, 0);
    
    if (sName=="AddOns" || sName=="Apps"){  //we only accept buttons for apps nemu
        
        string sSubMenu = llList2String(lParams, 1);
        list lGuts = llParseString2List(llList2String(g_lMenus, 1), ["|"], []);
        integer gutiIndex = llListFindList(lGuts, [sSubMenu]);
        //only remove if it's there
        if (gutiIndex != -1)        
        {
            lGuts = llDeleteSubList(lGuts, gutiIndex, gutiIndex);
            g_lMenus = llListReplaceList(g_lMenus, [llDumpList2String(lGuts, "|")], 1, 1);
        }        
    }
}

integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum == COMMAND_EVERYONE) return TRUE;  // No command for people with no privilege in this plugin.
    else if (iNum > COMMAND_EVERYONE || iNum < COMMAND_OWNER) return FALSE; // sanity check


    list lParams = llParseString2List(sStr, [" "], []);
    string sCmd = llList2String(lParams, 0);

    sCmd=llToLower(sCmd);
    //Debug("User command:'"+sStr+"'"+" "+(string)iNum);
    //Debug("User command:'"+sCmd+"'");

    if (sStr == "menu") Menu("Main", kID, iNum);
    else if (sCmd == "menu")
    {
        string sSubmenu = llGetSubString(sStr, 5, -1);
        if (sSubmenu == "AddOns") sSubmenu = "Apps";  // for compatible old AddOns menu, remove in future.
        if (llListFindList(g_lMenuNames, [sSubmenu]) != -1);
        Menu(sSubmenu, kID, iNum);
    }
    else if (sStr == "license") llGiveInventory(kID, LICENSECARD);    
    else if (sStr == "help") llGiveInventory(kID, HELPCARD); 
    else if (sStr =="about" || sStr=="help/about") Menu("Help/About",kID,iNum);               
    else if (sStr == "addons" || sStr=="apps") Menu("Apps", kID, iNum);
    else if (sCmd == "menuto") 
    {
        key kAv = (key)llList2String(lParams, 1);
        if (KeyIsAv(kAv))
        {
            if(llGetOwnerKey(kID)==kAv) Menu("Main", kID, iNum);
            else  llMessageLinked(LINK_SET, COMMAND_NOAUTH, "menu", kAv);
        }
    }
    
    else if (sStr == "settings")
    {
        if (g_iLocked) Notify(kID, "Locked.", FALSE);
        else Notify(kID, "Unlocked.", FALSE);
    }
    else if (sCmd == "lock" || (!g_iLocked && sStr == "togglelock"))
    {
        //Debug("User command:"+sCmd);

        if (iNum == COMMAND_OWNER || kID == g_kWearer )
        {   //primary owners and wearer can lock and unlock. no one else
            Lock();
            //            owner = kID; //need to store the one who locked (who has to be also owner) here
            Notify(kID, "Locked.", FALSE);
            if (kID!=g_kWearer) llOwnerSay("Your " + CTYPE + " has been locked.");
        }
        else Notify(kID, "Sorry, only primary owners and wearer can lock the " + CTYPE + ".", FALSE);
    }
    else if (sStr == "runaway" || sCmd == "unlock" || (g_iLocked && sStr == "togglelock"))
    {
        if (iNum == COMMAND_OWNER)
        {  //primary owners can lock and unlock. no one else
            Unlock();
            Notify(kID, "Unlocked.", FALSE);
            if (kID!=g_kWearer) llOwnerSay("Your " + CTYPE + " has been unlocked.");
        }
        else Notify(kID, "Sorry, only primary owners can unlock the " + CTYPE + ".", FALSE);
    }
    
    
    
    return TRUE;
}

NotifyOwners(string sMsg)
{
    integer n;
    integer stop = llGetListLength(g_lOwners);
    for (n = 0; n < stop; n += 2)
    {
        // Cleo: Stop IMs going wild
        if (g_kWearer != llGetOwner())
        {
            llResetScript();
            return;
        }
        else
            Notify((key)llList2String(g_lOwners, n), sMsg, FALSE);
    }
}

string GetPSTDate()
{ //Convert the date from UTC to PST if GMT time is less than 8 hours after midnight (and therefore tomorow's date).
    string DateUTC = llGetDate();
    if (llGetGMTclock() < 28800) // that's 28800 seconds, a.k.a. 8 hours.
    {
        list DateList = llParseString2List(DateUTC, ["-", "-"], []);
        integer year = llList2Integer(DateList, 0);
        integer month = llList2Integer(DateList, 1);
        integer day = llList2Integer(DateList, 2);
       // day = day - 1; //Remember, remember, the 0th of November!
       if(day==1)
       {
           if(month==1) return (string)(year-1) + "-01-31";
           else
           {
                --month;
                if(month==2) day = 28+(year%4==FALSE); //To do: fix before 28th feb 2100.
                else day = 30+ (!~llListFindList([4,6,9,11],[month])); //31 days hath == TRUE
            }
        }
        else --day;
        return (string)year + "-" + (string)month + "-" + (string)day;
    }
    return llGetDate();
}

string GetTimestamp() // Return a string of the date and time
{
    integer t = (integer)llGetWallclock(); // seconds since midnight

    return GetPSTDate() + " " + (string)(t / 3600) + ":" + PadNum((t % 3600) / 60) + ":" + PadNum(t % 60);
}

string PadNum(integer value)
{
    if(value < 10)
    {
        return "0" + (string)value;
    }
    return (string)value;
}

BuildLockElementList()//EB
{
    integer n;
    integer iLinkCount = llGetNumberOfPrims();
    list lParams;

    // clear list just in case
    g_lOpenLockElements = [];
    g_lClosedLockElements = [];

    //root prim is 1, so start at 2
    for (n = 2; n <= iLinkCount; n++)
    {
        // read description
        lParams=llParseString2List((string)llGetObjectDetails(llGetLinkKey(n), [OBJECT_DESC]), ["~"], []);
        // check inf name is lock name
        if (llList2String(lParams, 0)==g_sLockPrimName || llList2String(lParams, 0)==g_sClosedLockPrimName)
        {
            // if so store the number of the prim
            g_lClosedLockElements += [n];
        }
        else if (llList2String(lParams, 0)==g_sOpenLockPrimName) 
        {
            // if so store the number of the prim
            g_lOpenLockElements += [n];
        }
    }
}

SetLockElementAlpha() //EB
{
    if (g_iHide) return ; // ***** if collar is hide, don't do anything 
    //loop through stored links, setting alpha if element type is lock
    integer n;
    //float fAlpha;
    //if (g_iLocked) fAlpha = 1.0; else fAlpha = 0.0; //Let's just use g_iLocked!
    integer iLinkElements = llGetListLength(g_lOpenLockElements);
    for (n = 0; n < iLinkElements; n++)
    {
        llSetLinkAlpha(llList2Integer(g_lOpenLockElements,n), !g_iLocked, ALL_SIDES);
    }
    iLinkElements = llGetListLength(g_lClosedLockElements);
    for (n = 0; n < iLinkElements; n++)
    {
        llSetLinkAlpha(llList2Integer(g_lClosedLockElements,n), g_iLocked, ALL_SIDES);
    }
}

Lock()
{
    g_iLocked = TRUE;
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "Global_locked=1", "");
    llMessageLinked(LINK_SET, RLV_CMD, "detach=n", NULL_KEY);
    llPlaySound(g_sLockSound, 1.0);
    SetLockElementAlpha();//EB
}

Unlock()
{
    g_iLocked = FALSE;
    llMessageLinked(LINK_SET, LM_SETTING_DELETE, "Global_locked", "");
    llMessageLinked(LINK_SET, RLV_CMD, "detach=y", NULL_KEY);
    llPlaySound(g_sUnlockSound, 1.0);
    SetLockElementAlpha(); //EB
}

default
{
    state_entry()
    {
        //llOwnerSay("Menu: state entry:"+(string)llGetFreeMemory());
        g_kWearer = llGetOwner();
        BuildLockElementList();
        llSleep(1.0);//delay sending this message until we're fairly sure that other scripts have reset too, just in case
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "collarversion", "");
        g_iScriptCount = llGetInventoryNumber(INVENTORY_SCRIPT);
        MenuInit();
        //llSetMemoryLimit(llGetUsedMemory()+6000); //should be plenty, but let's keep an eye on this.
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        // SA: delete this after transition is finished
        if (iNum == COMMAND_NOAUTH) return;
        // /SA
        else if (iNum == MENUNAME_RESPONSE)
        {
            //sStr will be in form of "parent|menuname"
            //ignore unless parent is in our list of menu names
            HandleMenuResponse(sStr);
        }
        else if (iNum == MENUNAME_REMOVE)
        {
            HandleMenuRemove(sStr);
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            //Debug("Menu response");
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1)
            {
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);          
                string sMessage = llList2String(lMenuParams, 1);                                         
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                
                
                //process response
                if (sMenu=="Main"){
                    //Debug("Main menu response: '"+sMessage+"'");
                    if (sMessage == LOCK || sMessage == UNLOCK){
                        //Debug("doing usercommand for '"+sMessage+"' from "+sMenu+" menu");
                        UserCommand(iAuth, sMessage, kAv);
                        Menu("Main", kAv, iAuth);
                    } else if (sMessage == "Help/About"){
                        Menu("Help/About", kAv, iAuth);
                    } else if (sMessage == "Apps"){
                        Menu("Apps", kAv, iAuth);
                    } else {
                        //Debug("doing link message for 'menu "+sMessage+"' button from Apps menu");
                        llMessageLinked(LINK_SET, iAuth, "menu "+sMessage, kAv);
                    }
                } else if (sMenu=="Apps"){
                    //Debug("Main menu response");
                    if (sMessage == UPMENU) {
                        Menu("Main", kAv, iAuth);
                    } else {
                        //Debug("doing link message for 'menu "+sMessage+"' button from Apps menu");
                        llMessageLinked(LINK_SET, iAuth, "menu "+sMessage, kAv);
                    }
                } else if (sMenu=="Help/About"){
                    //Debug("Help menu response");
                    if (sMessage == UPMENU)
                    {
                        Menu("Main", kAv, iAuth);
                    }
                    else if (sMessage == GIVECARD)
                    {
                        llGiveInventory(kAv, HELPCARD);
                        Menu("Help/About", kAv, iAuth);
                    }
                    else if (sMessage == LICENSE)
                    {
                        if(llGetInventoryType(LICENSECARD)==INVENTORY_NOTECARD) llGiveInventory(kAv,LICENSECARD);
                        else Notify(kAv,"License notecard missing from collar, sorry.", FALSE); 
                        Menu("Help/About", kAv, iAuth);
                    }
                    else if (sMessage == WIKI)
                    {
                        llSleep(0.2);
                        llLoadURL(kAv, "\n\nVisit our homepage for help, discussion and news.\n", WIKI_URL);
                    }
                    else if (sMessage == BUGS)
                    {
                        llDialog(kAv,"Please help us to improve OpenCollar by reporting any bugs you see bugs. Click to open our support board at: \n"+BUGS_URL+"\n Or even better, use our github resource where you can create issues for bug reporting  / feature requests. \n https://github.com/OpenCollar/OpenCollarUpdater/issues\n\n(Creating a moot.it or github account is quick, simple, free and won't up your privacy. Forums could be fun.)",[],-39457);
                    }                        
                    else if (sMessage == DEV_GROUP)
                    {
                        llInstantMessage(kAv,"\n\nJoin secondlife:///app/group/" + DEV_GROUP_ID + "/about " + "for scripter talk.\nhttp://www.opencollar.at/forum.html#!/tinkerbox\n\n");
                        Menu("Help/About", kAv, iAuth);
                    }
                    else if (sMessage == USER_GROUP)
                    {
                        llInstantMessage(kAv,"\n\nJoin secondlife:///app/group/" + USER_GROUP_ID + "/about " + "for friendly support.\nhttp://www.opencollar.at/forum.html#!/support\n\n");
                        Menu("Help/About", kAv, iAuth);
                    }
                    else if (sMessage == "Update")
                    {
                        llMessageLinked(LINK_SET, iAuth, "menu Update", kAv);
                    }
                    else if (sMessage == "Get Updater")
                    {
                        llMessageLinked(LINK_SET, iAuth, "menu Get Updater", kAv);
                    }
                } else {
                    //Debug("Foreign menu response");
                }
            }
        }
        else if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if(sToken == "collarversion")
            {
                g_sCollarVersion=llList2String(lParams,1);
                g_iLatestVersion=(integer)llList2String(lParams,2);
            }
            else if (sToken == "Global_locked")
            {
                g_iLocked = (integer)sValue;
                SetLockElementAlpha(); //EB

            }
            else if (sToken == "Global_CType") CTYPE = sValue;
            else if (sToken == "auth_owner")
            {
                g_lOwners = llParseString2List(sValue, [","], []);
            }
            else if(sToken =="lock_locksound")
            {
                if(sValue=="default") g_sLockSound=g_sDefaultLockSound;
                else if((key)sValue!=NULL_KEY || llGetInventoryType(sValue)==INVENTORY_SOUND) g_sLockSound=sValue;
            }
            else if(sToken =="lock_unlocksound")
            {
                if(sValue=="default") g_sUnlockSound=g_sDefaultUnlockSound;
                else if((key)sValue!=NULL_KEY || llGetInventoryType(sValue)==INVENTORY_SOUND) g_sUnlockSound=sValue;
            }
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            //remove stride from g_lMenuIDs
            //we have to subtract from the index because the dialog id comes in the middle of the stride
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                        
        }
        else if (iNum == LM_SETTING_SAVE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "auth_owner")
            {
                g_lOwners = llParseString2List(sValue, [","], []);
            }
        }
        else if (iNum == RLV_REFRESH || iNum == RLV_CLEAR)
        {
            if (g_iLocked) llMessageLinked(LINK_SET, RLV_CMD, "detach=n", NULL_KEY);
            else llMessageLinked(LINK_SET, RLV_CMD, "detach=y", NULL_KEY);
        }
    }

    on_rez(integer iParam)
    {
        llResetScript();
    }
    
    changed(integer iChange)
    {
        if (iChange & CHANGED_INVENTORY)
        {
            if (llGetInventoryNumber(INVENTORY_SCRIPT) != g_iScriptCount)
            {//a script has been added or removed.  Reset to rebuild menu
                llResetScript();
            }
        }
        if (iChange & CHANGED_OWNER)
        {
            llResetScript();
        }
        if (iChange & CHANGED_COLOR) // ********************* 
        {
            integer iNewHide=!(integer)llGetAlpha(ALL_SIDES) ; //check alpha
            if (g_iHide != iNewHide){   //check there's a difference to avoid infinite loop
                g_iHide = iNewHide;
                SetLockElementAlpha(); // update hide elements 
            }
        }
        if (iChange & CHANGED_LINK) BuildLockElementList(); // need rebuils lockelements list
    }
    attach(key kID)
    {
        if (g_iLocked)
        {
            if(kID == NULL_KEY)
            {
                g_bDetached = TRUE;
                NotifyOwners(llKey2Name(g_kWearer) + " has detached me while locked at " + GetTimestamp() + "!");
            }
            else if(g_bDetached)
            {
                NotifyOwners(llKey2Name(g_kWearer) + " has re-atached me at " + GetTimestamp() + "!");
                g_bDetached = FALSE;
            }
        }
    }
}
