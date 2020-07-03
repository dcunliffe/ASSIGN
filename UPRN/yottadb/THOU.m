THOU ; ; 7/3/20 9:04am
 K
 K ^CSV
 S T=0,C=1
 ;S F="/tmp/UPRN-TH 3-9.txt"
 ;S F1="/tmp/yotta-TH 3-9.txt"
 ;S F="/tmp/UPRN-100K 3-9 Residential only.txt"
 ;S F1="/tmp/yotta-UPRN-100K 3-9 Residential only"
 ;S F="/tmp/V4-1 residential.txt"
 ;S F1="/tmp/yotta-V4-1 residential.txt"
 S F="/tmp/v4-2.txt"
 S F1="/tmp/yotta-v4-2.txt"
 C F,F1
 O F:(readonly)
 O F1:(newversion)
 U F R STR
 F  U F R STR Q:$ZEOF  DO
 .;U 0 W !,STR
 .S ID=$P(STR,$C(9))
 .S CADR=$$TR^LIB($P(STR,$C(9),7),"""","")
 .S MSMUPRN=$P(STR,$C(9),2)
 .I MSMUPRN=0 QUIT
 .D GETUPRN^UPRNMGR(CADR,"","","",0,0)
 .K b
 .D DECODE^VPRJSON($name(^temp($j,1)),$name(b),$name(err))
 .S YUPRN=$get(b("UPRN"))
 .I YUPRN'=MSMUPRN DO
 ..U 0 W !,ID," * ",CADR," * YOTTA=",YUPRN," * MSM=",MSMUPRN S T=T+1
 ..S ALG=$get(b("Algorithm"))
 ..S CLASS=$get(b("Classification"))
 ..S MATCH="",NODE="D"
 ..I YUPRN="" S YUPRN="ZZZZ"
 ..S KEY=$O(^TUPRN($J,"MATCHED",YUPRN,"D",""))
 ..S:KEY="" KEY=$O(^TUPRN($J,"MATCHED",YUPRN,"L","")),NODE="L"
 ..I KEY'="" S MATCH=$GET(^TUPRN($J,"MATCHED",YUPRN,NODE,KEY))
 ..S ^CSV(C)=ID_$C(9)_MSMUPRN_$C(9)_YUPRN_$C(9)_ALG_$C(9)_CLASS_$C(9)_MATCH_$C(9)_CADR
 ..S C=C+1
 ..QUIT
 .;U 0 W !,"TEST: " R *Y
 .QUIT
 C F
 U F1 W "id",$c(9),"Discovery UPRN",$c(9),"Yotta UPRN",$c(9),"Y Algorithm",$c(9),"Y Classification",$c(9),"Y Match",$c(9),"Candidate address",!
 S C="" F  S C=$O(^CSV(C)) Q:C=""  U F1 W ^(C),!
 C F1
 QUIT
