/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

#define MAXWARDS 64*4 //on map LOL
#define WARDBELOW -2.0 // player is 60 units tall about (6 feet)
#define WARDABOVE 160.0
#define WARDNAMELEN 64
#define WARDSNAMELEN 16
#define WARDDESCLEN 2001
#define MAXWARDBEHAVIORS 64*4 // Really, there shouldn't be this many ward types, but I want to be safe.
#define MAXWARDDATA 32	// That's 32 cells of data that can be passed to the ward behavior

// Ward info

new CurrentWardCount[MAXPLAYERSCUSTOM];
new Float:WardLocation[MAXWARDS][3]; 
new WardOwner[MAXWARDS];
new WardRadius[MAXWARDS];
new Float:WardDuration[MAXWARDS];
new Handle:WardTimer[MAXWARDS];
new bool:WardSelfInflict[MAXWARDS];
new War3WardAffinity:WardAffinity[MAXWARDS];
new Float:WardInterval[MAXWARDS];
new WardBehavior[MAXWARDS];
new any:WardData[MAXWARDS][MAXWARDDATA];

// Behavior info

new totalBehaviorsLoaded=0;
new String:behaviorName[MAXWARDBEHAVIORS][WARDNAMELEN];
new String:behaviorShortname[MAXWARDBEHAVIORS][WARDSNAMELEN];
new String:behaviorDescription[MAXWARDBEHAVIORS][WARDDESCLEN];

// Event handles
new Handle:g_OnWardCreatedHandle;
new Handle:g_OnWardPulseHandle;
new Handle:g_OnWardTriggerHandle;
new Handle:g_OnWardExpireHandle;

//new BeamSprite =-1;
//new HaloSprite =-1;

public Plugin:myinfo = 
{
	name = "WCX - Wards",
	author = "Invalid, necavi, PimpinJuice",
	description = "Ward Natives",
	version = "0.1",
	url = "http://necavi.com"
}

public OnPluginStart()
{
	//BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	//HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	
	/* Default Ward Behavior (0) */
	behaviorName[0] = "None";
	behaviorShortname[0] = "none";
	behaviorDescription[0] = "Default behavior";
}

public bool:InitNativesForwards()
{
	g_OnWardCreatedHandle=CreateGlobalForward("OnWardCreated",ET_Ignore,Param_Cell,Param_Cell);
	g_OnWardPulseHandle=CreateGlobalForward("OnWardPulse",ET_Ignore,Param_Cell,Param_Cell);
	g_OnWardTriggerHandle=CreateGlobalForward("OnWardTrigger",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
	g_OnWardExpireHandle=CreateGlobalForward("OnWardExpire",ET_Ignore,Param_Cell);

	CreateNative("War3_CreateWardBehavior", Native_War3_CreateWardBehavior);
	CreateNative("War3_GetWardBehaviorsLoaded", Native_War3_GetWardBehaviorsLoaded);
	CreateNative("War3_GetWardBehaviorName", Native_War3_GetWardBehaviorName);
	CreateNative("War3_GetWardBehaviorShortname", Native_War3_GetWardBehaviorShortname);
	CreateNative("War3_GetWardBehaviorDesc", Native_War3_GetWardBehaviorDesc);
	CreateNative("War3_GetWardBehaviorByShortname", Native_War3_GetWardBehaviorByShortname);
	
	CreateNative("War3_CreateWard", Native_War3_CreateWard);
	CreateNative("War3_GetWardBehavior", Native_War3_GetWardBehavior);
	CreateNative("War3_GetWardLocation", Native_War3_GetWardLocation);
	CreateNative("War3_GetWardInterval", Native_War3_GetWardInterval);
	CreateNative("War3_GetWardRadius", Native_War3_GetWardRadius);
	CreateNative("War3_GetWardOwner", Native_War3_GetWardOwner);
	CreateNative("War3_GetWardData", Native_War3_GetWardData);
	CreateNative("War3_RemoveWard", Native_War3_RemoveWard);
	return true;
}

public _:Native_War3_CreateWardBehavior(Handle:plugin,numParams)
{
	decl String:name[WARDNAMELEN],String:shortname[WARDSNAMELEN],String:desc[WARDDESCLEN];
	GetNativeString(1,shortname,sizeof(shortname));
	GetNativeString(2,name,sizeof(name));
	GetNativeString(3,desc,sizeof(desc));
	
	return CreateWardBehavior(shortname,name,desc);
}


public Native_War3_GetWardBehaviorsLoaded(Handle:plugin,numParams) {
	return _:GetBehaviorsLoaded();
}

public Native_War3_GetWardBehaviorName(Handle:plugin,numParams) {
	new id=GetNativeCell(1);
	new maxlen=GetNativeCell(3);
	
	new String:buf[WARDNAMELEN];
	GetBehaviorName(id,buf,sizeof(buf));
	SetNativeString(2,buf,maxlen);
}

public Native_War3_GetWardBehaviorShortname(Handle:plugin,numParams) {
	new id=GetNativeCell(1);
	new bufsize=GetNativeCell(3);
	if(id>=0 && id<=GetBehaviorsLoaded())
	{
		new String:shortname[WARDSNAMELEN];
		GetBehaviorShortname(id,shortname,sizeof(shortname));
		SetNativeString(2,shortname,bufsize);
	}
}

public Native_War3_GetWardBehaviorDesc(Handle:plugin,numParams) {
	new id=GetNativeCell(1);
	new maxlen=GetNativeCell(3);
	
	new String:longbuf[WARDDESCLEN];
	GetBehaviorDesc(id,longbuf,sizeof(longbuf));
	SetNativeString(2,longbuf,maxlen);
}

public _:Native_War3_GetWardBehaviorByShortname(Handle:plugin,numParams)
{
	new String:shortname[WARDSNAMELEN];
	GetNativeString(1,shortname,sizeof(shortname));
	return _:GetWardBehaviorByShortname(shortname);
}

public _:Native_War3_CreateWard(Handle:plugin,numParams)
{
	new client = GetNativeCell(1);
	
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]==0)
		{
			WardOwner[i]=client;
			GetNativeArray(2,WardLocation[i],3);
			WardRadius[i] = GetNativeCell(3);
			WardDuration[i] = Float:GetNativeCell(4);
			WardInterval[i] = Float:GetNativeCell(5);
			
			decl String:behavior[WARDSNAMELEN];
			GetNativeString(6,behavior,sizeof(behavior));
			WardBehavior[i] = GetWardBehaviorByShortname(behavior);
			
			GetNativeArray(7,WardData[i],MAXWARDDATA);
			
			WardSelfInflict[i] = bool:GetNativeCell(8);
			WardAffinity[i] = GetNativeCell(9);
			WardTimer[i] = CreateTimer(WardInterval[i],wardPulse,i,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			if (GetNativeCell(4) > 0) {
				CreateTimer(WardDuration[i],timedRemoveWard,i);
			}
			CurrentWardCount[client]++;
			
			Call_StartForward(g_OnWardCreatedHandle);
			Call_PushCell(i);
			Call_PushCell(WardBehavior[i]);
			Call_Finish();
			return i;
		}
	}
	return -1;
}

public _:Native_War3_GetWardBehavior(Handle:plugin,numParams)
{
	new id = GetNativeCell(1);
	if (WardOwner[id] == 0) {
		return -1;
	}
	
	return WardBehavior[id];
}

public Native_War3_GetWardLocation(Handle:plugin,numParams)
{
	new id = GetNativeCell(1);
	SetNativeArray(2,WardLocation[id],3);
}

public Native_War3_GetWardInterval(Handle:plugin,numParams)
{
	new id = GetNativeCell(1);
	return WardInterval[id];
}

public _:Native_War3_GetWardRadius(Handle:plugin,numParams)
{
	new id = GetNativeCell(1);
	return WardRadius[id];
}

public _:Native_War3_GetWardOwner(Handle:plugin,numParams)
{
	new id = GetNativeCell(1);
	return WardOwner[id];
}

public Native_War3_GetWardData(Handle:plugin,numParams)
{
	new id = GetNativeCell(1);
	
	SetNativeArray(2,WardData[id],MAXWARDDATA);
}

public Native_War3_RemoveWard(Handle:plugin,numParams)
{
	return bool:RemoveWard(GetNativeCell(1));
}

public Action:timedRemoveWard(Handle:timer,any:id) {
	RemoveWard(id);
}



GetBehaviorsLoaded() {
	return totalBehaviorsLoaded;
}

GetBehaviorShortname(id,String:retstr[],maxlen){
	new num=strcopy(retstr, maxlen, behaviorShortname[id]);
	return num;
}

GetBehaviorName(id,String:retstr[],maxlen){
	new num=strcopy(retstr, maxlen, behaviorName[id]);
	return num;
}

GetBehaviorDesc(id,String:retstr[],maxlen){
	new num=strcopy(retstr, maxlen, behaviorDescription[id]);
	return num;
}

bool:BehaviorExistsByShortname(String:shortname[]) {
	new String:buffer[WARDSNAMELEN];
	
	new BehaviorsLoaded = GetBehaviorsLoaded();
	for(new id=1;id<=BehaviorsLoaded;id++){
		GetBehaviorShortname(id,buffer,sizeof(buffer));
		if(StrEqual(shortname, buffer, false)){
			return true;
		}
	}
	return false;
}

CreateWardBehavior(String:shortname[], String:name[], String:desc[])
{
	if(BehaviorExistsByShortname(shortname)){
		new oldid=GetWardBehaviorByShortname(shortname);
		PrintToServer("Ward Behavior already exists: %s, returning old behavior id %d",shortname,oldid);
		return oldid;
	}
	
	if(totalBehaviorsLoaded+1==MAXWARDBEHAVIORS){ //make sure we didnt reach our behavior capacity limit
		LogError("[War3] MAX WARD BEHAVIORS REACHED, CANNOT REGISTER %s %s",name,shortname);
		return 0;
	}
	
	totalBehaviorsLoaded++;
	new id=totalBehaviorsLoaded;
	
	// Print a warning if a behavior name/shortname/description is truncated (exceeds max length)
	if (strlen(name) > WARDNAMELEN) {
		LogError("[War3] Ward Behavior (%s) name exceeds max length; truncated to %d characters",name,WARDNAMELEN);
	}
	if (strlen(shortname) > WARDSNAMELEN) {
		LogError("[War3] Ward Behavior (%s) shortname exceeds max length; truncated to %d characters",shortname,WARDSNAMELEN);
	}
	if (strlen(desc) > WARDDESCLEN) {
		LogError("[War3] Ward Behavior (%s) description exceeds max length; truncated to %d characters",desc,WARDDESCLEN);
	}
	
	strcopy(behaviorName[id], WARDNAMELEN, name);
	strcopy(behaviorShortname[id], WARDSNAMELEN, shortname);
	strcopy(behaviorDescription[id], WARDDESCLEN, desc);
	
	return id;
}

GetWardBehaviorByShortname(String:shortname[])
{
	new String:buffer[WARDSNAMELEN];
	
	new BehaviorsLoaded =GetBehaviorsLoaded();
	for(new id=0;id<=BehaviorsLoaded;id++){
		GetBehaviorShortname(id,buffer,sizeof(buffer));
		if(StrEqual(shortname, buffer, false)){
			return id;
		}
	}
	return -1;
}

public bool:RemoveWard(id)
{
	if (WardOwner[id] == 0)
	{
		return false;
	}
	
	Call_StartForward(g_OnWardExpireHandle);
	Call_PushCell(id);
	Call_PushCell(WardOwner[id]);
	Call_PushCell(WardBehavior[id]);
	Call_Finish();
	
	CurrentWardCount[WardOwner[id]]--;
	WardOwner[id] = 0;
	if (WardTimer[id] != INVALID_HANDLE)
	{
		CloseHandle(WardTimer[id]);
	}
	return true;
}


public RemoveWards(client)
{
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]==client)
		{
			RemoveWard(i);
		}
	}
}

public OnWar3EventSpawn(client)
{	
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]==client)
		{
			RemoveWard(i);
		}
	}
}

public Action:wardPulse(Handle:timer,any:wardindex) {
	new owner = WardOwner[wardindex];
	
	Call_StartForward(g_OnWardPulseHandle);
	Call_PushCell(wardindex);
	Call_PushCell(WardBehavior[i]);
	Call_Finish();
	
	new Float:start_pos[3];
	new Float:tempVec1[]={0.0,0.0,WARDBELOW};
	AddVectors(WardLocation[wardindex],tempVec1,start_pos);
	new Float:BeamXY[3];
	for(new x=0;x<3;x++) BeamXY[x]=start_pos[x]; //only compare xy
	new Float:BeamZ= BeamXY[2];
	BeamXY[2]=0.0;
	new Float:VictimPos[3];
	new Float:tempZ;
	
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true))
		{
			if (i == WardOwner[wardindex]) {
				if (!WardSelfInflict[wardindex]) {
					continue;
				}
			} else if (GetClientTeam(i) == GetClientTeam(WardOwner[wardindex])) {
				if (WardAffinity[wardindex] == ENEMIES || WardAffinity[wardindex] == SELF_ONLY) {
					continue;
				}
			} else {
				if (WardAffinity[wardindex] == ALLIES || WardAffinity[wardindex] == SELF_ONLY) {
					continue;
				}
			}
			
			GetClientAbsOrigin(i,VictimPos);
			tempZ=VictimPos[2];
			VictimPos[2]=0.0; //no Z
			if(GetVectorDistance(BeamXY,VictimPos) < WardRadius[wardindex]) ////ward RADIUS
			{
				// now compare z
				if(tempZ>BeamZ+WARDBELOW && tempZ < BeamZ+WARDABOVE)
				{
					Call_StartForward(g_OnWardTriggerHandle);
					Call_PushCell(wardindex);
					Call_PushCell(i);
					Call_PushCell(owner);
					Call_PushCell(WardBehavior[i]);
					Call_Finish();
				}
			}
		}
	}
}

/*
public WardEffect(wardindex) {
	
	new owner = WardOwner[wardindex];
	new beamcolor[4];
	if(WardType[wardindex]==true)
	{
		beamcolor={0,255,0,160};
	} else if(GetClientTeam(owner)==3)
	{
		beamcolor={0,0,255,160};
	} else {
		beamcolor={255,0,0,160};
	}
	
	
	new Float:start_pos[3];
	new Float:end_pos[3];
	new Float:tempVec1[]={0.0,0.0,WARDBELOW};
	new Float:tempVec2[]={0.0,0.0,WARDABOVE};
	AddVectors(WardLocation[wardindex],tempVec1,start_pos);
	AddVectors(WardLocation[wardindex],tempVec2,end_pos);
	TE_SetupBeamPoints(start_pos,end_pos,BeamSprite,HaloSprite,0,GetRandomInt(30,100),WardInterval[wardindex],70.0,70.0,0,30.0,beamcolor,10);
	TE_SendToAll()
	
	new Float:StartRadius = WardRadius[wardindex]/2.0;
	new Speed = RoundToFloor((WardRadius[wardindex]-StartRadius)/WardInterval[wardindex])
	
	TE_SetupBeamRingPoint(WardLocation[wardindex],StartRadius,float(WardRadius[wardindex]),BeamSprite,HaloSprite,0,1,WardInterval[wardindex],20.0,1.5,beamcolor,Speed,0);
	TE_SendToAll();
	new Float:BeamXY[3];
	for(new x=0;x<3;x++) BeamXY[x]=start_pos[x]; //only compare xy
	new Float:BeamZ= BeamXY[2];
	BeamXY[2]=0.0;
	new Float:VictimPos[3];
	new Float:tempZ;
	
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true))
		{
			if (i == WardOwner[wardindex]) {
				if (!WardSelfInflict[wardindex]) {
					continue;
				}
			} else if (GetClientTeam(i) == GetClientTeam(WardOwner[wardindex])) {
				if (WardAffinity[wardindex] == ENEMIES || WardAffinity[wardindex] == SELF_ONLY) {
					continue;
				}
			} else {
				if (WardAffinity[wardindex] == ALLIES || WardAffinity[wardindex] == SELF_ONLY) {
					continue;
				}
			}
			
			GetClientAbsOrigin(i,VictimPos);
			tempZ=VictimPos[2];
			VictimPos[2]=0.0; //no Z
			if(GetVectorDistance(BeamXY,VictimPos) < WardRadius[wardindex]) ////ward RADIUS
			{
				// now compare z
				if(tempZ>BeamZ+WARDBELOW && tempZ < BeamZ+WARDABOVE)
				{
					beamcolor[3]=20;
					if(WardType[wardindex]==true)
					{
						//Heal!!
						new cur_hp=GetClientHealth(i);
						new new_hp=cur_hp+WardDamage[owner];
						new max_hp=War3_GetMaxHP(i);
						if(new_hp>max_hp)	new_hp=max_hp;
						if(cur_hp<new_hp)
						{
							War3_HealToMaxHP(i,WardDamage[wardindex]);
							VictimPos[i]+=65.0;
							War3_TF_ParticleToClient(0, GetClientTeam(i)==2?"healthgained_red":"healthgained_blu", VictimPos);
						}
					} else {
						//Damage! !
						War3_DealDamage(i,WardDamage[wardindex],owner,_,"weapon_wards");
						VictimPos[i]+=65.0;
						War3_TF_ParticleToClient(0, GetClientTeam(i)==2?"healthgained_red":"healthgained_blu", VictimPos);
					}
				}
			}
		}
	}
}
*/


