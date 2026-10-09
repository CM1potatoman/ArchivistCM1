-- ============================================================
-- SETTINGS
-- ============================================================
local S = {
    HitboxEnabled=false, HitboxSize=10, HitboxTrans=0.5,
    FlyEnabled=false, FlySpeed=70, NoclipEnabled=false,
    WeaponEnabled=false, M1Speed=0.1, SwingSpeed=3,
    AnimEnabled=false, AnimSpeed=10,
    AttachEnabled=false, AttachTargetPlayers=false, AttachRange=20,
    AttachDistance=3, AttachForward=0, AttachHeight=-5.5,
    AutoFarmEnabled=false,
    NoRagdollEnabled=false, NoFallEnabled=false, NoStaminaEnabled=false,
    NoDashCDEnabled=false, NoCooldownsEnabled=false,
    HasteEnabled=false, WarpDashEnabled=false,
    ESPEnabled=false, ESPShowBox=true, ESPShowHealth=true, ESPShowName=true,
    ESPShowDist=false, ESPMaxDist=2000,
    LockonEnabled=false, LockonFOV=45, LockonMode="Cursor", LockonFilter="All",
    LockonStrength=80, LockonSmooth=true, LockonSmoothness=0.3,
    LockonPart="Root", LockonAuto=false, LockonShowFOV=true,
    ParryEnabled=false, ParryMode="Revamped", ParryDetection="All Attacks",
    ParryIndicatorEnabled=true, ParryTargetPlayers=false, ParrySpamEnabled=false,
    ParryEarlyBuffer=0.28, ParryRange=20, ParryAnimationTiming=true, ParryProfilerEnabled=false,
    MissChance=0, PanicChance=0, SkillParryDelay=0.45, AdjustToPing=true,
    ChainsInstakillEnabled=false, IndexCleaverEnabled=false, IndexCleaverHeight=100, ChainsGlideDelay=1.0, ChainsFloatDuration=3.5,
    NoKillbricksEnabled=false,
    AutoShin=false,
    AutoKillRange=10000,
}

local CharacterValues = {tpwalk=false, tpwalknum=1, infjump=false}
local EnemyValues = {autokill=false, autokillplayers=false, singuonly=false, wheelsIndustryPaced=false}
local QolValues = {permexp=false, gradeReq={[1]=10000,[2]=3000,[3]=2000,[4]=1900,[5]=1500,[6]=1300,[7]=1200,[8]=500,[9]=250}}

