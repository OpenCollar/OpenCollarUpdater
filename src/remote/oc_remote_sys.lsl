//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//       _   ___     __            __  ___  _                               //
//      | | / (_)___/ /___ _____ _/ / / _ \(_)__ ___ ________ ________      //
//      | |/ / / __/ __/ // / _ `/ / / // / (_-</ _ `/ __/ _ `/ __/ -_)     //
//      |___/_/_/  \__/\_,_/\_,_/_/ /____/_/___/\_, /_/  \_,_/\__/\__/      //
//                                             /___/                        //
//                                                                          //
//                                        _                                 //
//                                        \`*-.                             //
//                                         )  _`-.                          //
//                                        .  : `. .                         //
//                                        : _   '  \                        //
//                                        ; *` _.   `*-._                   //
//                                        `-.-'          `-.                //
//                                          ;       `       `.              //
//                                          :.       .        \             //
//                                          . \  .   :   .-'   .            //
//                                          '  `+.;  ;  '      :            //
//                                          :  '  |    ;       ;-.          //
//                                          ; '   : :`-:     _.`* ;         //
//       Remote System - 160110.2        .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2014 - 2015 Nandana Singh, Jessenia Mocha, Alexei Maven,  //
//  Master Starship, Wendy Starfall, North Glenwalker, Ray Zopf, Sumi Perl, //
//  Kire Faulkes, Zinn Ixtar, Builder's Brewery, Romka Swallowtail et al.   //
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
//         github.com/OpenCollar/opencollar/tree/master/src/remote          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

//merged HUD-menu, HUD-leash and HUD-rezzer into here June 2015 Otto (garvin.twine)

string g_sVersion = "160109.2";
string g_sFancyVersion = "¹⁶⁰¹⁰⁸⋅¹";
integer g_iUpdateAvailable;
key g_kWebLookup;

list g_lPartners;
list g_lNewPartnerIDs;
list g_lPartnersInSim; 
string g_sActivePartnerID = "ALL"; //either an UUID or "ALL"

//  list of hud channel handles we are listening for, for building lists
list g_lListeners;

string g_sMainMenu = "Main";

//  Notecard reading bits
string  g_sCard = ".partners";
key     g_kCardID = NULL_KEY;
key     g_kLineID;
integer g_iLineNr;

integer g_iListener;
integer g_iCmdListener;
integer g_iChannel = 7;

key g_kUpdater;
integer g_iUpdateChan = -7483210;

integer g_iHidden;
integer g_iPicturePrim;
string g_sPictureID;
key g_kPicRequest;
string g_sMetaFind = "<meta name=\"imageid\" content=\"";
string g_sTextureALL;

//  MESSAGE MAP
integer CMD_TOUCH            = 100;

integer MENUNAME_REQUEST     = 3000;
integer MENUNAME_RESPONSE    = 3001;
integer SUBMENU              = 3002;

integer DIALOG               = -9000;
integer DIALOG_RESPONSE      = -9001;
integer DIALOG_TIMEOUT       = -9002;

integer CMD_UPDATE    = 10001;

string UPMENU          = "BACK";

string g_sListPartners  = "List";
string g_sRemovePartner = "Remove";
string g_sAllPartners = "ALL";
string g_sAddPartners = "Add";

list g_lMainMenuButtons = [" ◄ ","ALL"," ► ",g_sAddPartners, g_sListPartners, g_sRemovePartner, "Collar Menu", "Rez"];

list g_lMenus ;

key    g_kRemovedPartnerID;
key    g_kOwner;

//  three strided list of avkey, dialogid, and menuname
key    g_kMenuID;
string g_sMenuType;

integer g_iScanRange        = 20;
integer g_iRLVRelayChannel  = -1812221819;
integer g_iRezChannel      = -987654321;
string  g_sRezObject;


/*integer g_iProfiled=1;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}*/

string NameURI(string sID) {
    if ((key)sID)
        return "secondlife:///app/agent/"+sID+"/about";
    else return sID;
}

integer PersonalChannel(key kID) {
    integer iChan = -llAbs((integer)("0x"+llGetSubString((string)kID,2,7)) + 1111);
    if (iChan > -10000) iChan -= 30000;
    return iChan;
}

SetCmdListener() {
    llListenRemove(g_iCmdListener);
    g_iCmdListener = llListen(g_iChannel,"",g_kOwner,"");
}

integer InSim(key kID) {
//  check if the AV is logged in and in Sim
    return (llGetAgentSize(kID) != ZERO_VECTOR);
}

list PartnersInSim() {
    list lTemp;
    integer i = llGetListLength(g_lPartners);
    if (i==0) return [];
    while (i) {
        string sTemp = llList2String(g_lPartners,--i);
        if (InSim(sTemp))
            lTemp += sTemp;
    }
    return ["ALL"]+lTemp;
}

SendCollarCommand(string sCmd) {
    if ((key)g_sActivePartnerID)
        llRegionSayTo(g_sActivePartnerID,PersonalChannel(g_sActivePartnerID), g_sActivePartnerID+":"+sCmd);
    else if (g_sActivePartnerID == "ALL") {
        integer i = llGetListLength(g_lPartnersInSim);
        do {
            string sPartnerID = llList2String(g_lPartnersInSim,--i);
            llRegionSayTo(sPartnerID,PersonalChannel(sPartnerID),sPartnerID+":"+sCmd);
        } while (i);
    }
}

AddPartner(string sID) {
    if (~llListFindList(g_lPartners,[sID])) return;
    if ((key)sID != NULL_KEY) {//don't register any unrecognised
        g_lPartners+=[sID];//Well we got here so lets add them to the list.
        llOwnerSay("\n\n"+NameURI(sID)+" has been registered.\n");//Tell the owner we made it.
    }
}

RemovePartner(string sID) {
    integer index = llListFindList(g_lPartners,[sID]);
    if (~index) {
        g_lPartners=llDeleteSubList(g_lPartners,index,index);
        if (InSim(sID)) {
            llRegionSayTo(sID,PersonalChannel(sID),sID+":rm owner");
            llRegionSayTo(sID,PersonalChannel(sID),sID+":rm trust");
        }
        llOwnerSay(NameURI(sID)+" has been removed from your Reomte HUD.");
    }
}

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, string sMenuType) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET,DIALOG,(string)kRCPT+"|"+sPrompt+"|"+(string)iPage+"|"+llDumpList2String(lChoices,"`")+"|"+llDumpList2String(lUtilityButtons,"`"),kID);
    g_kMenuID = kID;
    g_sMenuType = sMenuType;
}

MainMenu(){
    string sPrompt = "\n[http://www.opencollar.at/remote.html OpenCollar Remote] "+g_sFancyVersion;
    sPrompt += "\n\nActive Partner:\n\t"+NameURI(g_sActivePartnerID);
    if (g_iUpdateAvailable) sPrompt += "\n\nThere is an update available @ [http://maps.secondlife.com/secondlife/Boulevard/50/211/23 The Temple]";
    list lButtons = g_lMainMenuButtons + g_lMenus;
    Dialog(g_kOwner, sPrompt, lButtons, [], 0, g_sMainMenu);
}

RezzerMenu() {
    Dialog(g_kOwner, "\nMake your choice!\n\nChoosen Partner for this Object will be:\n\t"+NameURI(g_sActivePartnerID), BuildObjectList(),["BACK"],0,"RezzerMenu");
}

RemovePartnerMenu() {
    Dialog(g_kOwner, "\nWho would you like to remove?\n\nNOTE: This will also revoke your access rights.", g_lPartners, [UPMENU], -1,"RemovePartnerMenu");
}

ConfirmPartnerRemove(key kID) {
    string sPrompt = "\nAre you sure you want to remove "+NameURI(kID)+"?\n\nNOTE: This will also revoke your access rights.";
    Dialog(g_kOwner, sPrompt, ["Yes", "No"], [UPMENU], 0,"RemovePartnerMenu");
}

AddPartnerMenu() {
    string sPrompt = "\nChoose who you want to manage:";
    list lButtons;
    integer index;
    integer iSpaceIndex;
    string sName;
    do {
        lButtons += llList2Key(g_lNewPartnerIDs,index);
    } while (++index < llGetListLength(g_lNewPartnerIDs));
    Dialog(g_kOwner, sPrompt, lButtons, ["ALL",UPMENU], -1,"AddPartnerMenu");
}

StartUpdate() {
    integer pin = (integer)llFrand(99999998.0) + 1;
    llSetRemoteScriptAccessPin(pin);
    llRegionSayTo(g_kUpdater, g_iUpdateChan, "ready|" + (string)pin );
}

list BuildObjectList() {
    list lRezObjects;
    integer i;
    do lRezObjects += llGetInventoryName(INVENTORY_OBJECT,i);
    while (++i < llGetInventoryNumber(INVENTORY_OBJECT));
    return lRezObjects;
}

NextPartner(integer iDirection, integer iTouch) {
    g_lPartnersInSim = PartnersInSim();
    if (iDirection) {
        integer index = llListFindList(g_lPartnersInSim,[g_sActivePartnerID])+iDirection;
        if (index >= llGetListLength(g_lPartnersInSim)) index = 0;
        else if (index < 0) index = llGetListLength(g_lPartnersInSim)-1;
        g_sActivePartnerID = llList2String(g_lPartnersInSim,index);
    } else g_sActivePartnerID = "ALL";
    if ((key)g_sActivePartnerID)
        g_kPicRequest = llHTTPRequest("http://world.secondlife.com/resident/"+g_sActivePartnerID,[HTTP_METHOD,"GET"],"");
    else if (g_sActivePartnerID == "ALL")
        if (g_iPicturePrim) llSetLinkPrimitiveParamsFast(g_iPicturePrim,[PRIM_TEXTURE, ALL_SIDES, g_sTextureALL,<1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
    if(iTouch) llOwnerSay("New Active Partner is "+NameURI(g_sActivePartnerID));
}

integer PicturePrim() {
    integer i = llGetNumberOfPrims();
    do {
        if (~llSubStringIndex((string)llGetLinkPrimitiveParams(i, [PRIM_DESC]),"Picture"))
            return i;
    } while (--i>1);
    return 0;
}

default {
    state_entry() {
        g_kOwner = llGetOwner();
        g_kWebLookup = llHTTPRequest("https://raw.githubusercontent.com/VirtualDisgrace/Collar/live/web/~remote", [HTTP_METHOD, "GET"],"");
        llSleep(1.0);//giving time for others to reset before populating menu
        if (llGetInventoryKey(g_sCard)) {
            g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
            g_kCardID = llGetInventoryKey(g_sCard);
        }
        g_iListener=llListen(PersonalChannel(g_kOwner),"",NULL_KEY,""); //lets listen here
        SetCmdListener();
        llMessageLinked(LINK_SET,MENUNAME_REQUEST, g_sMainMenu,"");
        g_iPicturePrim = PicturePrim();
        //Debug("started.");
    }
    
    on_rez(integer iStart) {
        g_kWebLookup = llHTTPRequest("https://raw.githubusercontent.com/VirtualDisgrace/Collar/live/web/~remote", [HTTP_METHOD, "GET"],"");
    }
    
    touch_start(integer iNum) {
        key kID = llDetectedKey(0);
        if ((llGetAttached() == 0)&& (kID==g_kOwner)) {// Dont do anything if not attached to the HUD
            llMessageLinked(LINK_THIS, CMD_UPDATE, "Update", kID);
            return;
        }
        if (kID == g_kOwner) {
//          I made the root prim the "menu" prim, and the button action default to "menu."
            string sButton = (string)llGetLinkPrimitiveParams(llDetectedLinkNumber(0),[PRIM_DESC]);
            if (~llSubStringIndex(sButton,"remote"))
                llMessageLinked(LINK_SET, CMD_TOUCH,"hide","");
            else if (sButton == "Menu") MainMenu();
            else if (~llSubStringIndex(sButton,"Picture")) NextPartner(1,TRUE);
            else SendCollarCommand(llToLower(sButton));
        }
    }

    listen(integer iChannel, string sName, key kID, string sMessage) {
        if (iChannel == g_iChannel) {
            list lParams = llParseString2List(sMessage, [" "], []);
            string sCmd = llList2String(lParams,0);
            if (sMessage == "menu")
                MainMenu();
            else if (sCmd == "channel") {
                integer iNewChannel = (integer)llList2String(lParams,1);
                if (iNewChannel) {
                    g_iChannel = iNewChannel;
                    SetCmdListener();
                    llOwnerSay("Your new HUD command channel is "+(string)g_iChannel+". Type /"+(string)g_iChannel+"menu to bring up your HUD menu.");
                } else llOwnerSay("Your HUD command channel is "+(string)g_iChannel+". Type /"+(string)g_iChannel+"menu to bring up your HUD menu.");
            }
            else if (llToLower(sMessage) == "help")
                llOwnerSay("\n\nThe manual page can be found [http://www.opencollar.at/remote.html here].\n");
            else if (sMessage == "reset") llResetScript();
        } else if (iChannel == PersonalChannel(g_kOwner) && llGetOwnerKey(kID) == g_kOwner) {
            if (sMessage == "-.. --- / .... ..- -..") {
                g_kUpdater = kID;
                Dialog(g_kOwner, "\nINSTALLATION REQUEST PENDING:\n\nAn update or app installer is requesting permission to continue. Installation progress can be observed above the installer box and it will also tell you when it's done.\n\nShall we continue and start with the installation?", ["Yes","No"], ["Cancel"], 0, "UpdateConfirmMenu");
            }
        } else if (llGetSubString(sMessage, 36, 40)==":pong") {
            if (!~llListFindList(g_lNewPartnerIDs, [llGetOwnerKey(kID)]) && !~llListFindList(g_lPartners, [llGetOwnerKey(kID)]))
                g_lNewPartnerIDs += [llGetOwnerKey(kID)];
        } 
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_RESPONSE) {
            list lParams = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParams,0) == g_sMainMenu) {
                string sChild = llList2String(lParams,1);
                if (! ~llListFindList(g_lMenus, [sChild]))
                    g_lMenus = llListSort(g_lMenus+=[sChild], 1, TRUE);
            }
            lParams = [];
        }
        else if (iNum == SUBMENU && sStr == "Main") MainMenu();
        else if (iNum == 111) {
            g_sTextureALL = sStr;
            if (g_sActivePartnerID == "ALL") 
                llSetLinkPrimitiveParamsFast(g_iPicturePrim,[PRIM_TEXTURE, ALL_SIDES, g_sTextureALL , <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
        } else if (iNum == DIALOG_RESPONSE && kID == g_kMenuID) {
            list lParams = llParseString2List(sStr, ["|"], []);
            string sMessage = llList2String(lParams, 1);
            integer i;
            if (g_sMenuType == "Main") {
                if (sMessage == "Collar Menu") SendCollarCommand("menu");
                else if (sMessage == "Rez") RezzerMenu();
                else if (sMessage == g_sRemovePartner) RemovePartnerMenu();
                else if (sMessage == g_sListPartners) { //Lets List out partners
                    //list lTemp;
                    string sText ="\nI'm currently managing:\n";
                    integer iPartnerCount = llGetListLength(g_lPartners);
                    if (iPartnerCount) {
                        i=0;
                        do {
                            if (llStringLength(sText)>950) {
                                llOwnerSay(sText);
                                sText ="";
                            }
                            sText += NameURI(llList2Key(g_lPartners,i))+", " ;
                        } while (++i < iPartnerCount-1);
                        if (iPartnerCount>1)sText += " and "+NameURI(llList2Key(g_lPartners,i));
                        if (iPartnerCount == 1) sText = llGetSubString(sText,0,-3);
                    } else sText += "nobody";
                    llOwnerSay(sText);
                    MainMenu();
                } else if (sMessage == g_sAddPartners) {
                     // Ping for auth OpenCollars in the parcel
                     list lAgents = llGetAgentList(AGENT_LIST_PARCEL, []); //scan for who is in the parcel
                     llOwnerSay("Scanning for collars where you have access to.");
                     integer iChannel;
                     for (i=0; i < llGetListLength(lAgents); ++i) {//build a list of who to scan
                        kID = llList2Key(lAgents,i);
                        if (kID != g_kOwner && llListFindList(g_lPartners,[(string)kID]) == -1) {
                            if (llGetListLength(g_lListeners) < 60) { // lets not cause "too many listen" error
                                iChannel = PersonalChannel(kID);
                                g_lListeners += [llListen(iChannel, "", "", "" )] ;
                                llRegionSayTo(kID, iChannel, (string)kID+":ping");
                            }
                        }
                    }
                    llSetTimerEvent(2.0);
                } else if (sMessage == " ◄ ") {
                    NextPartner(-1,FALSE);
                    MainMenu();
                } else if (sMessage == " ► ") {
                    NextPartner(1,FALSE);
                    MainMenu();
                } else if (sMessage == "ALL") {
                    g_sActivePartnerID = "ALL";
                    NextPartner(0,FALSE);
                    MainMenu(); 
                } else if (~llListFindList(g_lMenus,[sMessage])) llMessageLinked(LINK_SET,SUBMENU,sMessage,kID);
            } else if (g_sMenuType == "RemovePartnerMenu") {
                integer index = llListFindList(g_lPartners, [sMessage]);
                if (sMessage == UPMENU) MainMenu();
                else if (sMessage == "Yes") {
                    RemovePartner(g_kRemovedPartnerID);
                    MainMenu();
                } else if (sMessage == "No") MainMenu();
                else if (~index) {
                    g_kRemovedPartnerID = (key)llList2String(g_lPartners, index);
                    ConfirmPartnerRemove(g_kRemovedPartnerID);
                }
            } else if (g_sMenuType == "UpdateConfirmMenu") {
                if (sMessage=="Yes") StartUpdate();
                else {
                    llOwnerSay("Installation cancelled.");
                    return;
                }
            } else if (g_sMenuType == "RezzerMenu") {
                    if (sMessage == UPMENU) MainMenu();
                    else { 
                        g_sRezObject = sMessage;
                        if (llGetInventoryType(g_sRezObject) == INVENTORY_OBJECT)
                            llRezObject(g_sRezObject,llGetPos() + <2, 2, 0>, ZERO_VECTOR, llGetRot(), 0);
                    }
            } else if (g_sMenuType == "AddPartnerMenu") {
                if (sMessage == "ALL") {
                    i=0;
                    key kNewPartnerID;
                    do {
                        kNewPartnerID = llList2Key(g_lNewPartnerIDs,i);
                        if (kNewPartnerID) AddPartner(kNewPartnerID);
                    } while (i++ < llGetListLength(g_lNewPartnerIDs));
                } else if ((key)sMessage)
                    AddPartner(sMessage);
                g_lNewPartnerIDs = [];
                MainMenu();
            }
        }
    }

//  clear things after ping
    timer() {
        //Debug ("timer expired" + (string)llGetListLength(g_lCageVictims));
        if (llGetListLength(g_lNewPartnerIDs)) AddPartnerMenu();
        else llOwnerSay("No one is not found");
        llSetTimerEvent(0);
        integer n = llGetListLength(g_lListeners);
        while (n--)
            llListenRemove(llList2Integer(g_lListeners,n));
        g_lListeners = [];
    }

    dataserver(key kRequestID, string sData) {
        if (kRequestID == g_kLineID) {
            if (sData == EOF) { //  notify the owner
                llOwnerSay(g_sCard+" card loaded.");
                return;
            } else if (sData != "") {//  if we are not working with a blank line
                if (llSubStringIndex(sData, "#")) {//  if the line does not begin with a comment
                    if ((key)sData) AddPartner(sData);
                }
            }
            g_kLineID = llGetNotecardLine(g_sCard, ++g_iLineNr);//  read the next line
        }
    }
    
    http_response(key kRequestID, integer iStatus, list lMeta, string sBody) {
        if (kRequestID == g_kWebLookup && iStatus == 200)  {
            if ((float)sBody > (float)g_sVersion) g_iUpdateAvailable = TRUE;
            else g_iUpdateAvailable = FALSE;
        } else if (kRequestID == g_kPicRequest) {
            integer iMetaPos =  llSubStringIndex(sBody, g_sMetaFind) + llStringLength(g_sMetaFind);
            if (g_iPicturePrim) llSetLinkPrimitiveParamsFast(g_iPicturePrim,[PRIM_TEXTURE, ALL_SIDES,  llGetSubString(sBody, iMetaPos, iMetaPos + 35),<1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
        }
    }
    
    object_rez(key kID) {
        llSleep(0.5); // make sure object is rezzed and listens
        if (g_sActivePartnerID == "ALL") 
            llRegionSayTo(kID,g_iRezChannel,llDumpList2String(PartnersInSim(),","));
        else 
            llRegionSayTo(kID,g_iRezChannel,g_sActivePartnerID);
    }
    
    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) {
            if (llGetInventoryKey(g_sCard) != g_kCardID) {
                // the .partners card changed.  Re-read it.
                g_iLineNr = 0;
                if (llGetInventoryKey(g_sCard)) {
                    g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
                    g_kCardID = llGetInventoryKey(g_sCard);
                }
            }
        }
        if (iChange & CHANGED_OWNER) llResetScript();
    }
}
