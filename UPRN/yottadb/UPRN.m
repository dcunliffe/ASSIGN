UPRN ;Command line for processing a batch of adresses [ 05/12/2023  8:47 AM ]
 K ^UPRN("MX") ;[ 05/11/2023  12:26 PM ]
 K ^UPRN("UX")
 K ^UPRNI("UM")
 K ^UPRNI("Stats")
 K ^UPRNI("M")
 K ^TPARAM($J)
CONT ;Re-entry point
 ;S ^TPARAM($J,"commercials")=1
 s from=""
 s to=1000000000
 s ui=0
 s country="e"
setarea d batch("D","",from,to,ui,country)
 d stats
 q
 
 ;
 
stats ;End of run stats
 ;
 s total=$G(^UPRNI("Stats","Total"))
 S matched=$G(^UPRNI("Stats","Matched"))
 s invalid=$G(^UPRNI("Stats","Invalid"))
 s unmatched=$G(^UPRNI("Stats","Unmatched"))
 s out=$G(^UPRNI("Stats","OutOfArea"))
 s missing=$G(^UPRNI("Stats","Missing post code"))
 s invpost=$G(^UPRNI("Stats","Invalid post code"))
 w !!,"Total processed : ",total
 w !,"Matched : ",matched
 w !,"Unmatched=",unmatched
 w !,"Invalid : ",invalid
 w !,"Invalid post code : "_invpost
 w !,"Out of area=",out
 w !,"Missing post code :",missing
 w !,"Percentage :",$j(matched/total*100,1,2)_"%"
 w !,"Percentage with valid addresses : "_$j(matched/(total-(out+invalid+invpost))*100,1,2)_"%"
 q
 
 ;
batch(mkey,qpost,from,to,ui,country)   ;Processes a batch of addresses for a list of areas
 ;mkey is the node for the address list
 n adno
 ;qpost is the , delimited list of addresses
 ;
 n total
 s xh=$p($H,",",2)
 ;lower case the post code filter
 set qpost=$$lc^UPRNL(qpost)
 
 ;Initiate the spelling swap  and corrections
 d SETSWAPS^UPRNU
 ;Loop through the table of addresses, 
 
 ;Set File delimiter
 set d="~"
   
 ;Initiate the counts
 
 set adno=""
 set total=0
 for  set adno=$O(^UPRNI(mkey,adno)) q:adno=""  q:adno>to  d
 .S ^ADNO=adno
 .d tomatch(adno,qpost,ui,country) ;Match 1 address
 .s total=total+1
 .i $d(adflat) d
 ..S ^UPRNI(mkey,adno,"f")=adflat_"~"_adbuild_"~"_adbno_"~"_adepth_"~"_adstreet_"~"_adeploc_"~"_adloc_"~"_adpost
 .i '$D(^TUPRN($J,"MATCHED")) I $D(^UPRNI("Prev",adno)) d
 ..I $D(^TUPRN($J,"INVALID")) D
 ...S ^UPRNI("Invalid",adno)=""
 ..I $D(^TUPRN($J,"POSTCODE")) D
 ...S ^UPRNI("Nopost",adno)=""
 ..s ouprn=^UPRNI("Prev",adno)
 ..i ouprn="" q
 ..S ^UPRNI("mismatch",adno)=ouprn
 .;I '(adno#1000) d
 ..w !,"Matched "_adno
 ..d stats
 q
 
tomatch(adno,qpost,ui,country)      ;Match one Discovery address
 
 ;Remove from unmatched and matched resultset list
 K ^UPRNI("UM",adno)
 s ADNO=adno
 S ^UPRNI("Stats","Total")=$G(^UPRNI("Stats","Total"))+1
 
 K ^UPRNI("M",adno)
 
 ;Initiate global find variabls
 ;Retrieve address record
 set adrec=^UPRNI("D",adno)
 D GETUPRN(adrec,"","","")
 i $D(^TUPRN($J,"INVALID")) D
 .s ^UPRNI("Stats","Invalid")=$g(^UPRNI("Stats","Invalid"))+1
 I $D(^TUPRN($J,"OUTOFAREA")) D
 .S ^UPRNI("Stats","OutOfArea")=$G(^UPRNI("Stats","OutOfArea"))+1
 I $G(^TUPRN($J,"POSTCODE"))'="" d
 .S ^UPRNI("Stats",^TUPRN($J,"POSTCODE"))=$G(^UPRNI("Stats",^TUPRN($J,"POSTCODE")))+1
 
 I $D(^TUPRN($J,"MATCHED")) D SETBATCH(1)
 E  D SETBATCH(0)
 ;
 q
GETUPRN(adrec,qpost,orgpost,country,summary) ;Returns the result of a matching request
 ;adrec is an address string with post code at the end
 ;qpost is list of post code areas (optional)
 ;orgpost is the post code of a local organisatoin to narrow down search
 k ^TUPRN($J)
 s adrec=$tr(adrec,",","~")
 s adrec=$tr(adrec,"""")
 s adrec=$tr(adrec,$c(13))
 s adrec=$tr(adrec,$c(10))
 s country=$$lc^UPRNL($g(country))
 s summary=$g(summary)
 I country="" s country="e"
 s country=$s($e(country)="e":"e",$e(country)="w":"w",1:"o")
 ;Checks for library update
 I '$D(^UPRNS("DROPSUFFIX")) D SETSWAPS^UPRNU
 ;Checks quality of address
 D ADRQUAL(adrec,country)
 I '$D(^TUPRN($J,"INVALID")) D
 .D MATCHONE(adrec,$g(qpost),$g(orgpost))
 E  D
 .S ^TUPRN($J,"NOMATCH")=""
EAPI q
ADRQUAL(rec,country)         ;
 n missing,nopost,invadr,invpost
 s (missing,nopost,invadr,invpost)=0
 s rec=$$lc^UPRNL(rec)
 I $tr(rec,"~")="" d
 .S ^TUPRN($J,"INVALID")="Null address lines"
 .s missing=1
 E  i $l($tr(rec,"~"))<9 d  q
 .S ^TUPRN($J,"INVALID")="Insufficient characters"
 .s invadr=1
 set rec=$tr(rec,"}{","")
 set length=$length(rec,"~")
 set post=$$lc^UPRNL($p(rec,"~",length))
 set post=$tr(post," ") ;Remove spaces
 i post="" d
 .S ^TUPRN($J,"POSTCODE")="Missing post code"
 E  d
 .i country="e"!(country="w") d
 ..i '$$validp(post),$get(qpost)="" D  Q
 ...S ^TUPRN($J,"POSTCODE")="Invalid post code"
 i post'="",$l(rec,"~")=2,$p(rec,"~")'[" " d
 .i $l($p(rec,"~"))<10,$g(qpost)="" d
 ..S ^TUPRN($J,"INVALID")="Insufficient characters"
 i post'="",$l(rec,"~")=2,$D(^UPRNX("X.STR",$p(rec,"~"))) d
 .S ^TUPRN($J,"INVALID")="Insufficient characters"
 q
validp(post)       ;
 s post=$$lc^UPRNL(post)
 i post?2l1n1l1n2l q 1
 i post?1l1n1l1n2l q 1
 i post?1l2n2l q 1
 i post?1l3n2l q 1
 i post?2l2n2l q 1
 i post?2l3n2l q 1
 q 0
 
MATCHONE(adrec,qpost,orgpost,ui)    ;matches one address
 s d="~"
 n quit
 s quit=0
 K ^TPOSS($J)
 set adrec=$$LC^LIB(adrec)
 set adrec=$tr(adrec,"}{""","")
 set adrec=$$welsh^UPRN1(adrec)
        
 set length=$length(adrec,d)
 set post=$$lc^UPRNL($p(adrec,d,length))
 set post=$tr(post," ") ;Remove spaces
 set qpost=$$lc^UPRNL(qpost)
 set orgpost=$tr($$lc^UPRNL(orgpost)," ")
 
 ;OutOfArea
 i post'="" d  i quit q
 .i $$validp(post) d
 ..i '$$inpost(post,qpost) d  q
 ...s ^TUPRN($J,"OUTOFAREA")="Post code out of areas"
 ...s ^TUPRN($J,"UNMATCHED")=""
 ...s quit=1
 
 
 ;formats the address ready for action
 d format^UPRNA(adrec,.address)
 ;
 ;format the address record
 D SETADS
 i adpstreet'=adstreet s adplural=1
 if adpbuild'=adbuild s adplural=1
 set adb2=""
 set adf2=""
 i adbuild'="",adflat?1n.n1" "1l.l d
 .s adb2=$p(adflat," ",2,10)_" "_adbuild
 .s adf2=$p(adflat," ")
 
 s indrec=adpost_" "_adflat_" "_adbuild_" "_adbno_" "_adepth_" "_adstreet_" "_adeploc_" "_adloc
 for  q:(indrec'["  ")  s indrec=$$tr^UPRNL(indrec,"  "," ")
 s indrec=$$lt^UPRNL(indrec)
 i adplural d
 .s indprec=adpost_" "_adflat_" "_adpbuild_" "_adbno_" "_adepth_" "_adpstreet_" "_adeploc_" "_adloc
 .for  q:(indprec'["  ")  s indprec=$$tr^UPRNL(indprec,"  "," ")
 .s indprec=$$lt^UPRNL(indrec)
 
 k ^TUPRN($J,"MATCHED")
 
 
 
 ;clear down variables
 do clrvars
 
 ;Exact match all fields directly i.e. 1 candidate
 D match(adflat,adbuild,adbno,adepth,adstreet,adeploc,adloc,adpost,adf2,adb2)
 i $D(^TUPRN($J,"MATCHED"))  D  Q
 .d matched
 D SETADS
 i adbuild'="",adflat'="",adbno="",adstreet'="" d  i $D(^TUPRN($J,"MATCHED")) d matched q
 .s adbno=adflat,adstreet=adbuild_" "_adstreet,adflat="",adbuild=""
 .d match(adflat,adbuild,adbno,adepth,adstreet,adeploc,adloc,adpost,adf2,adb2)
 i $D(^TUPRN($J,"MATCHED"))  D  Q
 .d matched
 D SETADS
 i adbuild'="" d
 .D match(adflat,"former "_adbuild,adbno,adepth,adstreet,adeploc,adloc,adpost,adf2,adb2)
 i $D(^TUPRN($J,"MATCHED")) d  q 
 .d matched
 ;
 D SETADS
 i adbuild="",adflat'="",adloc'="",adstreet'="" d
 .d match(adflat,adstreet,adbno,"",adloc,"","",adpost,"","")
 i $D(^TUPRN($J,"MATCHED")) d  q 
 .d matched
 ;Is it ground floor?
 D SETADS
 i $p(address," ")?1n.n,adflat?1n.n d
 .D match("g"_$P(address," "),adbuild,adbno,adepth,adstreet,adeploc,adloc,adpost,adf2,adb2)
 i $D(^TUPRN($J,"MATCHED")) d  q 
 .d matched
 I $p(address,"~",2)?1"flat "1n.n.e d
 .d reformat^UPRNA(.address)
 .d SETADS
 .D match(adflat,adbuild,adbno,adepth,adstreet,adeploc,adloc,adpost,adf2,adb2)
 i $D(^TUPRN($J,"MATCHED")) d  q 
 .d matched
 
 
010221 I '$d(^TUPRN($J,"MATCHED")) D  Q
 .d nomatch
 q
SETADS ;
 set adflat=address("flat")
 set adbuild=address("building")
 set adbno=address("number")
 set adstreet=address("street")
 set adloc=address("locality")
 set adpost=address("postcode")
 set adepth=address("depth")
 set adeploc=address("deploc")
 set adpstreet=$$plural^UPRNU(adstreet)
 set adpbuild=$$plural^UPRNU(adbuild)
 set adflatbl=$$flat^UPRNU(adbuild_" ")
 set adplural=0
 Q
 
 
match(adflat,adbuild,adbno,adepth,adstreet,adeploc,adloc,adpost,adf2,adb2) ;
 ;Match algorithms
 K ^UPRNT("Considered")
 K ^UPRNT("Stats","Matched")
 n matched,post,build,street,bno,depth,deploc,town
 s matched=0
 s ALG=""
 
 ;Reject crap codes
 if adflat="",adbuild="",adbno="",adstreet="",adepth="" q
 
 
 ;Full match on post,street, building and flat
 ;Try concatenated fields
1 s matches=$$matchall(indrec)
 I $D(^TUPRN($J,"MATCHED")) Q
 s matches=$$matchall($g(address("original")))
 I $D(^TUPRN($J,"MATCHED")) Q
 
 ;Exact field match single and plural and correction
10 S ALG="10-"
 s matchrec="Pe,Se"
 s matches=$$match1(adpost,adstreet,adbno,adbuild,adflat)
 i $d(^TUPRN($J,"MATCHED")) Q
 I adplural d
 .s matches=$$match1(adpost,adpstreet,adbno,adpbuild,adflat)
 i $d(^TUPRN($J,"MATCHED")) Q
 s corstr=$$correct^UPRNU(adstreet)
 i corstr'=adstreet d
 .s matches=$$match1(adpost,corstr,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
 
 
 ;Full match on dependent street
 i adepth'="" d
20 .s ALG="20-"
 .s matches=$$match1(adpost,adepth_" "_adstreet,adbno,adbuild,adflat)
 .i $D(^TUPRN($J,"MATCHED")) Q
 .I adplural d
 ..s matches=$$match1(adpost,adepth_" "_adpstreet,adbno,adpbuild,adflat)
 .I $D(^TUPRN($J,"MATCHED")) Q
30 .S ALG="30-"
 .s matches=$$match1(adpost,adepth,adbno,adbuild,adflat)
 .i $D(^TUPRN($J,"MATCHED")) Q
 .i adplural d
 ..s matches=$$match1(adpost,adepth,adbno,adpbuild,adflat)
 i $D(^TUPRN($J,"MATCHED")) Q
 
 
35 ;Flat in number
 i adbno?1n.n1l,adflat="",adbuild="" d
 .S ALG="35-"
 .s matches=$$match1(adpost,adstreet,adbno*1,adbuild,$p(adbno,adbno*1,2))
 I $D(^TUPRN($J,"MATCHED")) Q
 
36 ;Building in flat
 i adflat?1n.n.l1" "1l.e d
 .S ALG="36-"
 .s matches=$$match1(adpost,adstreet,adbno,$p(adflat," ",2,10),$p(adflat," "))
 I $D(^TUPRN($J,"MATCHED")) Q
 
37 ;Flat contains number and suffix. Street and building
 I adflat?1n.n1l,adbno="",adbuild'="" d
 .S ALG="37-"
 .s matches=$$match1(adpost,adbuild,adflat*1,"",$p(adflat,adflat*1,2))
 
 I $D(^TUPRN($J,"MATCHED")) Q
 
 ;Full match Swap building flat with number and street
40 s ALG="40-"
 s matches=$$match1(adpost,adbuild,adflat,adstreet,adbno)
 I $D(^TUPRN($J,"MATCHED")) Q
 s matches=$$match1(adpost,adbuild,adbno,adstreet,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 i adplural d
 .s matches=$$match1(adpost,adpbuild,adflat,adstreet,adbno)
 I $D(^TUPRN($J,"MATCHED")) q
 
 
 ;Full match locality swap for street
 i '$D(^TUPRN($J,"MATCHED")),adloc'="" d
50 .S ALG="50-"
 .set matchrec="Pe,Se"
 .s matches=$$match1(adpost,adloc,adbno,adbuild,adflat)
 .i $D(^TUPRN($J,"MATCHED")) Q
 .i adplural d
 ..s matches=$$match1(adpost,adloc,adbno,adpbuild,adflat)
 i $D(^TUPRN($J,"MATCHED")) Q
 
 ;Full match Try swapping flat and mumber
 I '$D(^TUPRN($J,"MATCHED")) D
60 .S ALG="60-"
 .S matches=$$match4(adpost,adstreet,adbno,adbuild,adflat)
 .I $D(^TUPRN($J,"MATCHED")) Q
 .I adplural d
 ..S matches=$$match4(adpost,adpstreet,adbno,adpbuild,adflat)
 i $D(^TUPRN($J,"MATCHED")) q
 
65 ;Flat is number, partial building
 i adbno="" d
 .s ALG="65-"
 .s matches=$$match33(adpost,adstreet,adbno,adbuild,adflat)
 i $D(^TUPRN($J,"MATCHED")) Q
 
 ;Special flat in building
 i adflatbl'=(adbuild_" "),adflat'="" d
70 .s ALG="70-"
 .s matches=$$match1(adpost,adstreet,adbno,"",adflatbl_adflat)
 
 I $d(^TUPRN($J,"MATCHED")) Q
 
 
 ;Part building in flat
 i adf2'="" d
80 .S ALG="80-"
 .s matches=$$match1(adpost,adstreet,adbno,adb2,adf2)
 i $D(^TUPRN($J,"MATCHED")) Q
 
85 ;Match with flat equivalent, may or may not be post code
 S ALG="85-"
 s matches=$$match48(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
 ;Full match with street spelling corrections
 s matchrec="Pe,Se"
90 S ALG="90-"
 I adstreet'="" d
 .s word=$p(adstreet," "),sword=word
 .s sword=""
 .for  s sword=$O(^UPRNW("SFIX",word,sword)) q:sword=""  d  I $D(^TUPRN($J,"MATCHED")) Q
 ..s strno=""
 ..for  s strno=$O(^UPRNX("X.W",sword,"STR",strno)) q:strno=""  d  q:$D(^TUPRN($J,"MATCHED"))
 ...s street=^UPRN("STR",strno)
 ...I '$$mcount^UPRNU($p(adstreet," ",2,10),$p(street," ",2,10)) q
 ...S ALG="90-"
 ...set matchrec="Pe,Sl"
 ...s matches=$$match1(adpost,street,adbno,adbuild,adflat)
 ...i $D(^TUPRN($J,"MATCHED")) Q
 ...i adflat'="",adbuild'="" d
100 ....s ALG="100-"
 ....s matches=$$match1(adpost,street,adbno,adflat_" "_adbuild,"")
 ....i $D(^TUPRN($J,"MATCHED")) q  
 ...I adf2'="" d
110 ....S ALG="110-"
 ....s matches=$$match1(adpost,street,adbno,adb2,adf2)
 ....I $D(^TUPRN($J,"MATCHED")) Q
 ...i $D(^TUPRN($J,"MATCHED")) Q
120 ...S ALG="120-"
 ...s matches=$$match2(adpost,street,adbno,adbuild,adflat)
 ...I $D(^TUPRN($J,"MATCHED")) Q
 ...i adbno?1n.n1l,adflat="" d
125 ....s ALG="125-"
 ....s matches=$$match1(adpost,street,adbno*1,adbuild,$p(adbno,adbno*1,2))
 i $d(^TUPRN($J,"MATCHED")) Q
 
128 ;Match on range number
 s ALG="128-"
 s matches=$$match101(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
129 ;flat,building, number, street, very close post code
 S ALG="129-"
 s matches=$$match102(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
 ;Matches post code street and number, try fuzzy building/ flat       
130 s ALG="130-"
 s matches=$$match2(adpost,adstreet,adbno,adbuild,adflat,adloc)
 i $D(^TUPRN($J,"MATCHED")) Q
 
131 ;Closish post code, exact flat, number street and near enough building
 S ALG="131-"
 s matches=$$match203(adpost,adstreet,adbno,adbuild,adflat)
 i $D(^TUPRN($J,"MATCHED")) Q
 
132 ;Fuzzy building / flat
 S ALG="132-"
 s matches=$$match202(adpost,adstreet,adbno,adbuild,adflat)
 i $D(^TUPRN($J,"MATCHED")) Q
 
 i adepth'="" d
140 .s ALG="140-"
 .s matches=$$match2(adpost,adepth_" "_adstreet,adbno,adbuild,adflat)
 i $D(^TUPRN($J,"MATCHED")) Q
 
160 ;Matches on post code, street,building number=flat, mismatch on number
 i adstreet'="",adbuild'="",adflat'="",adbno="" d
 .s ALG="160-"
 .s matchrec="Pe"
 .s matches=$$match6(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
200 ;Matches flat,building, street, near post code
 ;Only if number matches or null
 i adbuild'="",adflat'="",adstreet'="" d
 .s ALG="200-"
 .s matches=$$match6b(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
 ;Match on street and number, try another post code
 I '$D(^TUPRN($J,"MATCHED")),adstreet'="" d
300 .s ALG="300-"
 .s matchrec=",Se"
 .s matches=$$match7(adpost,adstreet,adbno,adbuild,adflat)
 .i adflat="",adbno?1n.n1l d
 ..s matches=$$match32(adpost,adstreet,adbno,adbuild,adflat)
 i $D(^TUPRN($J,"MATCHED")) Q
 
350 ;near post code Matches with flat and building split out from street
 I '$D(^TUPRN($J,"MATCHED")),adbno'="",adflat="",adbuild="",adstreet'="" d
 .S ALG="350-"
 .s matches=$$match28(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
i ;Swaps building and street try another post code
 I '$d(^TUPRN($J,"MATCHED")),adbuild'="" d
310 .s ALG="310-"
 .s matches=$$match7(adpost,adbuild,adflat,adstreet,adbno)
 
j ;Parse building from street and use number as flat
 i '$D(^TUPRN($J,"MATCHED")) d
500 .S ALG="500-"
 .s matches=$$match5(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
5501 ;Drop building, number is flat
 S ALG="550-"
 s matches=$$match5a(adpost,adstreet,adbno,adbuild,adflat)
 i $D(^TUPRN($J,"MATCHED")) Q
 
 ;Parse building from street and use number as flat,ignore number
 i '$D(^TUPRN($J,"MATCHED")) d
550 .S ALG="550-"
 .s matches=$$match5b(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
k ;try different post code on levenstreet
 I '$D(^TUPRN($J,"MATCHED")),adstreet'="" d
600 .s ALG="600-"
 .I adbno="",adbuild="" q  ;Wrong post code Not enough fields
 .s word=$p(adstreet," "),sword=word
 .s sword=""
 .for  s sword=$O(^UPRNW("SFIX",word,sword)) q:sword=""  d  I $D(^TUPRN($J,"MATCHED")) Q
 ..s strno=""
 ..for  s strno=$O(^UPRNX("X.W",sword,"STR",strno)) q:strno=""  d  q:$D(^TUPRN($J,"MATCHED"))
 ...s street=^UPRN("STR",strno)
 ...I '$$mcount^UPRNU($p(adstreet," ",2,10),$p(street," ",2,10)) q
 ...s matchrec=",Sl"
 ...s matches=$$match7(adpost,street,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
620 ;street=building, ood building name and post code, missing street
 i adbuild="",$l(adstreet," ")>2,adbno="",adflat="" d
 .s ALG="620"
 .s matches=$$match59(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
650 ;Try different post code on extended levenstreet
 
 
l ;Try equivalent and levenshtein on building as street
 i '$d(^TUPRN($J,"MATCHED")),adbuild'="" d
700 .S ALG="700-"
 .s build=""
 .s matchrec="Pe"
 .for  s build=$O(^UPRNX("X5",adpost,build)) q:build=""  d
 ..i $$equiv^UPRNU(build,adbuild) d
 ...S $p(matchrec,",",2)="Sl"
 ...s matches=$$match1(adpost,build,adflat,adstreet,adbno)
 ...I $D(^TUPRN($J,"MATCHED")) Q
 ...S $p(matchrec,",",2)="Sl"
 ...s matches=$$match2(adpost,build,adflat,adstreet,adbno)
 
750 ;Pattetn : Candidate has 25a flat 1, ABP has flat 25a
 ;I $D(^TUPRN($J,"MATCHED")) Q
 ;S ALG="750-"
 ;s matches=$$match5f(adpost,adstreet,adbno,adbuild,adflat)
 
m ;Now try approximation of number
 I '$D(^TUPRN($J,"MATCHED")),adstreet'="",adbno'="" d
800 .s ALG="800-"
 .s matchrec="Pe"
 .s matches=$$match6(adpost,adstreet,adbno,adbuild,adflat)
 
850 ;Now skip number and go for building and flat approx
 I '$D(^TUPRN($J,"MATCHED")),adstreet'="",adbno="",adbuild'="",adflat'="" d
 .s ALG="850-"
 .s matchrec="Pe"
 .s matches=$$match6(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
 I '$D(^TUPRN($J,"MATCHED")),adbno'="",adflat'="",adbuild'="",adstreet'="" d
900 .s ALG="900-"
 .s matches=$$match21(adpost,adstreet,adbno,adbuild,adflat)
 I $G(^TUPRN($J,"MATCHED")) Q
 
 
 ;Wrong street, try post code - building flat 
 i '$D(^TUPRN($J,"MATCHED")),adbuild'="",adflat'="" d
1000 .S ALG="1000-"
 .set matchrec="Pe,,,Be,Fe"
 .set matches=$$match3(adpost,adstreet,adbno,adbuild,adflat)
 
1050 ;Left shift locality,street and mumber, ignore number
 I '$D(^TUPRN($J,"MATCHED")),adloc'="",adflat="",adbuild="",adbno'="",adstreet'="" d
 .S ALG="1050-"
 .set matchrec="Pe,,Be,Fe"
 .set matches=$$match3(adpost,adloc,"",adstreet,adbno)
 i $D(^TUPRN($J,"MATCHED")) Q
 
1060 ;Swap street, number to building and flat if null fields
 i adbuild="",adflat="",adstreet'="",adbno'="" d
 .s ALG="1060-"
 .set matchrec="Pe,,Be,Fe"
 .set matches=$$match3(adpost,"","",adstreet,adbno)
 I $D(^TUPRN($J,"MATCHED")) Q
 
 
 ;right post code approx street
 I '$D(^TUPRN($J,"MATCHED")) D
1100 .s ALG="1100-"
 .s matchrec="Pe"
 .s matches=$$match11(adpost,adstreet,adbno,adbuild,adflat,adloc)
 
p ;Completely wrong post code so needs a building, number and street
 I '$D(^TUPRN($J,"MATCHED")) D
1200 .s ALG="1200-"
 .i adstreet'="",adbno'="",adbuild'="" d
 ..s matches=$$match14(adpost,adstreet,adbno,adbuild,adflat)
 
 ;Swap building and street and fuzzy match
 S matchrec="Pe"
 I '$D(^TUPRN($J,"MATCHED")) D
1300 .s ALG="1300-"
 .I adbuild'="",adbno'="" d
 ..s matches=$$match2(adpost,adbuild,adbno,adstreet,adflat)
 
r ;Drop suffix from the number
 i '$D(^TUPRN($J,"MATCHED")) D
1400 .s ALG="1400-"
 .s matches=$$match15(adpost,adstreet,adbno,adbuild,adflat)
 
s ; street number wandered into flat field
 I '$D(^TUPRN($J,"MATCHED")) D
1500 .s ALG="1500-"
 .s matches=$$match17(adpost,adstreet,adbno,adbuild,adflat)
 
t ; missing number so needs to match on building and flat
 I '$D(^TUPRN($J,"MATCHED")) D
1600 .s ALG="1600-"
 .s matches=$$match18(adpost,adstreet,adbno,adbuild,adflat,adloc)
 I $D(^TUPRN($J,"MATCHED")) Q
 
u ;post code street match but high level on flat and building
 i '$D(^TUPRN($J,"MATCHED")) d
1700 .s ALG="1700-"
 .s matches=$$match19(adpost,adstreet,adbno,adbuild,adflat)
 
v ;Levenshtein street, drop number if flat and building, different post
 I '$D(^TUPRN($J,"MATCHED")),adstreet'="" d
1800 .s ALG="1800-"
 .I adbno=""!(adflat="")!(adbuild="") q
 .s word=$p(adstreet," "),sword=word
 .s sword=""
 .for  s sword=$O(^UPRNW("SFIX",word,sword)) q:sword=""  d  I $D(^TUPRN($J,"MATCHED")) Q
 ..s strno=""
 ..for  s strno=$O(^UPRNX("X.W",sword,"STR",strno)) q:strno=""  d  q:$D(^TUPRN($J,"MATCHED"))
 ...s street=^UPRN("STR",strno)
 ...I '$$mcount^UPRNU($p(adstreet," ",2,10),$p(street," ",2,10)) q
 ...s matchrec=",Sl"
 ...s matches=$$match20(adpost,street,"",adbuild,adflat)
 
w ;street and number was building and flat with missing street
 I '$D(^TUPRN($J,"MATCHED")),adstreet'="",adbno'="",adbuild="",adflat="" d
1900 .s ALG="1900-"
 .s matchrec="Pe"
 .s matches=$$match22(adpost,adstreet,adbno,adbuild,adflat)
 
x ;building is in locality, street contains flat
 I '$D(^TUPRN($J,"MATCHED")),adloc'="",adstreet'="",adbuild="",adflat="" d
2000 .s ALG="2000-"
 .s matches=$$match23(adpost,adstreet,adbno,adloc,adflat)
 
y ;In case of suffix numbers
 I '$D(^TUPRN($J,"MATCHED")),adbno'="" d
2100 .s ALG="2100-"
 .s matches=$$match24(adpost,adstreet,adbno,adbuild,adflat)
 
22001 ;Concatenate number and flat
 I '$D(^TUPRN($J,"MATCHED")),adflat?1l,adbno?1n.n d
 .s ALG="2200-"
 .s matchrec=",Se"
 .s matches=$$match7(adpost,adstreet,adbno_adflat,adbuild,"")
 
p1 ;Completely wrong post code ignore, building, null flat, needs number and street
 I '$D(^TUPRN($J,"MATCHED")) D
2300 .s ALG="2300-"
 .i adstreet'="",adbno'="",adbuild="" d
 ..s matches=$$match14(adpost,adstreet,adbno,adbuild,adflat,1)
 
 ;Street is building, missing number and street, exact flat
2350 ;
 I '$D(^TUPRN($J,"MATCHED")) d
 .S ALG="2350-"
 .s matches=$$match52(adpost,adstreet,adbno,adbuild,adflat)
 i $D(^TUPRN($J,"MATCHED")) Q
 
 ;right post code last chance for approx street
 I '$D(^TUPRN($J,"MATCHED")) D
2400 .s ALG="2400-"
 .s matchrec="Pe"
 .s matches=$$match11(adpost,adstreet,adbno,adbuild,adflat,1)
 I $D(^TUPRN($J,"MATCHED")) Q
 
2450 ;Number wandered into buildng, building not in ABP
 i adflat'="",adbuild?1n.n.l1" "1l.e d
 .s ALG="2450-"
 .s matches=$$match34(adpost,adstreet,$p(adbuild," "),$p(adbuild," ",2,10),adflat)
 i $D(^TUPRN($J,"MATCHED")) Q
 
2455 ;Drop number and street, building and flat is number and street
 ;or shift street to locality
 I '$D(^TUPRN($J,"MATCHED")) D
 .S ALG="2455-"
 .s matchrec="Pe"
 .s matches=$$match27(adpost,adstreet,adbno,adbuild,adflat)
 
2500 ;Exact or Near post code, Swap flat into number, parse out flat from building
 I '$D(^TUPRN($J,"MATCHED")) D
 .S ALG="2500-"
 .s matches=$$match25(adpost,adstreet,adbno,adbuild,adflat)
 
2550 ;Near post code, exact on flat and building
 I '$D(^TUPRN($J,"MATCHED")) d
 .S ALG="2550-"
 .s matches=$$match29(adpost,adstreet,adbno,adbuild,adflat)
 ;
2570 ;Very odd flat building fuzzy match, patial post code
 I '$D(^TUPRN($J,"MATCHED")) D
 .s ALG="2570-"
 .s matches=$$match30(adpost,adstreet,adbno,adbuild,adflat)
 
2571 ;Wrong post, levenshtein street, flat equivalent in number
 I '$D(^TUPRN($J,"MATCHED")) D
 .s ALG="2571-"
 .s matches=$$match31(adpost,adstreet,adbno,adbuild,adflat)
 
2572 ;Wrong post, building is street, flat is number and flat
 I '$D(^TUPRN($J,"MATCHED")) D
 .S ALG="2572-"
 .s matches=$$match35(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
2573 ;Levenshtein building is actually mispelled street
 I '$D(^TUPRN($J,"MATCHED")) d
 .S ALG="2573-"
 .s matches=$$match36(adpost,adstreet,adbno,adbuild,adflat)
 
2574 ;Number is flat and partial  building match
 I '$D(^TUPRN($J,"MATCHED")) D
 .S ALG="2574-"
 .s matches=$$match37(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
2575 ;Approximate post code building in wrong place
 I '$D(^TUPRN($J,"MATCHED")) D
 .S ALG="2575-"
 .s matches=$$match29a(adpost,adstreet,adbno,adbuild,adflat)
 
 ;Very close number,may be wrong post code
2576 I '$D(^TUPRN($J,"MATCHED")) D
 .S ALG="2576-"
 .s matches=$$match38(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
2577 ;Building doesn't match, complex flat
 I '$D(^TUPRN($J,"MATCHED")) D
 .S ALG="2577-"
 .s matches=$$match39(adpost,adstreet,adbno,adbuild,adflat)
 
2578 ;Number is actually flat, flat is building, no actual number
 I '$D(^TUPRN($J,"MATCHED")) D
 .i adflat'="",adbuild="",adbno'="" d
 .S ALG="2578-"
 .s matches=$$match1(adpost,adstreet,"",adflat,adbno)
 I $d(^TUPRN($J,"MATCHED")) Q
 
2579 ;Flat is number, ignore building 
 I '$D(^TUPRN($J,"MATCHED")) D
 .S ALG="2579-"
 .i adflat'="",adbuild'="" d
 ..s matches=$$match40(adpost,adstreet,adbno,adbuild,adflat)
 i $g(^TUPRN($J,"MATCHED")) Q
 
2580 ;Numner is flat, street number is null, ignore building 
 I '$D(^TUPRN($J,"MATCHED")) D
 .S ALG="2580-"
 .s matches=$$match41(adpost,adstreet,adbno,adbuild,adflat)
 
2581 ;Building and street formatted wrong way round
 ;Number has suffix and flat needs parsing
 I '$D(^TUPRN($J,"MATCHED")) D
 .S ALG="2581-"
 .s matches=$$match42(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
2582 ;Wrong post code for fuzzy building and wrong number
 I '$D(^TUPRN($J,"MATCHED")) D
 .S ALG="2582-"
 .s matches=$$match43(adpost,adstreet,adbno,adbuild,adflat)
 
2583 ;Matches on number range, ignore building and flat
 ; match44a is faulty and creating false positives
 ;I '$D(^TUPRN($J,"MATCHED")) D
 ;.S ALG="2583-"
 ;.s matches=$$match44(adpost,adstreet,adbno,adbuild,adflat)
 
 ;Long shot for post code drop number, very fuzzy on building
2584 I '$D(^TUPRN($J,"MATCHED")) D
 .S ALG="2584-"
 .s matches=$$match45(adpost,adstreet,adbno,adbuild,adflat)
 i $d(^TUPRN($J,"MATCHED")) Q
 
 
 ;Building and street match, flat match with suffix
 ;Wrong post code, ignore number
 ;Student address giving office address
2585 I '$D(^TUPRN($J,"MATCHED")) D
 .S ALG="2585-"
 .s matches=$$match46(adpost,adstreet,adbno,adbuild,adflat)
 
 ;Wrong post code, street, number, building, child flat
2586 I '$D(^TUPRN($J,"MATCHED")) D
 .S ALG="2586-"
 .s matches=$$match47(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
2587 ;Flat suffix in number and suffix is equivalent to building
 S ALG="2587-"
 s matches=$$match49(adpost,adstreet,adbno,adbuild,adflat)
 
 ;Ignore street, partial post code
 
2589 ;
 S ALG="2589-"
 s matches=$$match51(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
2590 ;Another 3 field match with discovery missing number and building
 S ALG="2590-"
 s matches=$$match53(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) Q
 
2600 ;post code numebr match, first part street and building
 ;Locality with street number
 S ALG="2600-"
 s matches=$$match54(adpost,adstreet,adbno,adbuild,adflat,adloc)
 I $D(^TUPRN($J,"MATCHED")) Q
 
2700 ;Number moved to flat, locality ignored
 S ALG="2700-"
 s matches=$$match55(adpost,adstreet,adbno,adbuild,adflat,adloc)
 I $D(^TUPRN($J,"MATCHED")) Q
 
2800 ;Post code match,street match,number match but number suffix not in ABP
 S ALG="2800-"
 ;ABP doesnt contain building and flat 
 s matches=$$match56(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) q
 
2900 ;Former house problem
 S ALG="2900-"
 ;ABP doesnt contain building and flat 
 s matches=$$match57(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) q
 S ALG="3000-"
 ;ABP doesnt contain building and flat 
 s matches=$$match58(adpost,adstreet,adbno,adbuild,adflat)
 I $D(^TUPRN($J,"MATCHED")) q
 
3100 ;shift flat to number, building to street,street to locality
 ;No number
 S ALG="3100-"
 s matches=$$match60(adpost,adstreet,adbno,adbuild,adflat,adloc)
 
 I $D(^TUPRN($J,"MATCHED")) Q
3200 ;Post code, street and number but has mismatch in 
 S ALG="3200-"
 s matches=$$match61(adpost,adstreet,adbno,adbuild,adflat,adloc,adeploc)
 I $D(^TUPRN($J,"MATCHED")) Q
 
3300 ;
 S ALG="3300-"
 s matches=$$match62(adpost,adstreet,adbno,adbuild,adflat,adloc,adeploc)
 
3400 ;
 I $D(^TUPRN($J,"MATCHED")) Q
 S ALG="3400-"
 s matches=$$match63^UPRNC(adpost,adstreet,adbno,adbuild,adflat,adloc,adeploc)
 Q
 q
 
 
 ;
match23(tpost,tstreet,tbno,tbuild,tflat)          ;
 ;Location is building, strip flat out of street
 n i
 f i=1:1:$l(tstreet," ") d  q:$d(^TUPRN($J,"MATCHED"))
 .s street=$p(tstreet," ",1,i)
 .I $D(^UPRNX("X5",tpost,street,tbno,tbuild)) do
 ..s tflat=$p(tstreet," ",i+1,10)
 ..I $$mflat(tpost,street,tbno,tbuild,tflat,.flat,.approx) d
 ...s $p(matchrec,",",2)="Se"
 ...s $p(matchrec,",",3)="Ne"
 ...s $p(matchrec,",",4)="Be"
 ...s $p(matchrec,",",5)="F"_approx
 ...s ALG=ALG_"match23"
 ...s matched=$$setuprns("X5",tpost,street,tbno,tbuild,flat)
 q $D(^TUPRN($J,"MATCHED"))
 
 
match22(tpost,tstreet,tbno,tbuild,tflat)          ;
 
 ;Checks the building index
 i $D(^UPRNX("X3",tstreet,tbno,tpost)) d
 .s street=""
 .for  s street=$O(^UPRNX("X5",tpost,street)) q:street=""  d  Q:$D(^TUPRN($J,"MATCHED"))
 ..I $D(^UPRNX("X5",tpost,street,"",tstreet,tbno)) d
 ...s $p(matchrec,",",2,3)="Si,Ne"
 ...s $p(matchrec,",",4,5)="Be,Fe"
 ...s ALG=ALG_"match22"
 ...s matched=$$setuprns("X5",tpost,street,"",tstreet,tbno)
 Q $G(^TUPRN($J,"MATCHED"))
 
match20(tpost,tstreet,tbno,tbuild,tflat)          ;
 ;Alternative post codes for null street number
 ;e152pu , 1 castor park road, 1 casitor house
 ;= e153pu, caistor park road, caistor house, 1
 s post=""
 for  s post=$O(^UPRNX("X3",tstreet,"",post)) q:post=""  d  q:$G(^TUPRN($J,"MATCHED"))
 .q:post=tpost
 .s matchrec=$$nearpost(post,tpost)
 .i matchrec="" q
 .s matches=$$match20a(post,tstreet,tbno,tbuild,tflat)
 I $G(^TUPRN($J,"MATCHED"))>1 d prefer
 q $g(^TUPRN($J,"MATCHED"))
 
match20a(post,tstreet,tbno,tbuild,tflat) 
 ;Wrong post code, drop street number must match on building flat
 ;levensthein building bu exact on flat
 N matched
 s matched=0
 S $p(matchrec,",",2,3)="Se,Ne"
 ;Looping through UPRNs for match
 s uprn=""
 for  s uprn=$O(^UPRNX("X3",tstreet,"",post,uprn)) q:uprn=""  d  Q:matched
 .s table=""
 .for  s table=$O(^UPRNX("X3",tstreet,"",post,uprn,table)) q:table=""  d  Q:matched
 ..s key=""
 ..for  s key=$O(^UPRNX("X3",tstreet,"",post,uprn,table,key)) q:key=""  d  q:matched
 ...D GETADR^UPRNU(uprn,table,key,.flat,.build,.bno,.depth,.street,.deploc,.loc,.town,.lpost,.org)
 ...I $$equiv^UPRNU(build,tbuild) d
 ....i tflat=flat d
 .....s $p(matchrec,",",4,5)="Bl,Fe"
 .....s ALG=ALG_"match20"
 .....s matched=$$set(uprn,table,key)
 Q $G(^TUPRN($J,"MATCHED"))
 
match21(tpost,tstreet,tbno,tbuild,tflat)          ;
 ;Checks building flat and post code and works back
 i '$d(^UPRNX("X3",tbuild,tflat)) q 0
 s post=""
 for  s post=$O(^UPRNX("X3",tbuild,tflat,post)) q:post=""  d  q:$G(^TUPRN($J,"MATCHED"))
 .q:post=tpost
 .s matchrec=$$nearpost(post,adpost)
 .i matchrec="" q
 .i '$D(^UPRNX("X5",post,tstreet)) q
 .s bno=""
 .for  s bno=$O(^UPRNX("X5",post,tstreet,bno)) q:bno=""  d  q:$D(^TUPRN($J,"MATCHED"))
 ..i $D(^UPRNX("X5",post,tstreet,bno,tbuild,tflat)) d
 ...s $p(matchrec,",",2)="Se"
 ...s $p(matchrec,",",3)="Ni"
 ...s $p(matchrec,",",4,5)="Be,Fe"
 ...s ALG=ALG_"match21"
 ...s matched=$$setuprns("X5",post,tstreet,bno,tbuild,tflat)
 q $G(^TUPRN($J,"MATCHED"))
match29(tpost,tstreet,tbno,tbuild,tflat)          ;
 ;Checks building flat and post code and works back
 i tbuild="" q 0
 i tflat="" q 0
 i $$match29a(tpost,tstreet,tbno,tbuild,tflat) q 1
 s word=$p(tbuild," "),sword=word
 s sword=""
 for  s sword=$O(^UPRNW("SFIX",word,sword)) q:sword=""  d  I $D(^TUPRN($J,"MATCHED")) Q
 .s bldno=""
 .for  s bldno=$O(^UPRNX("X.W",sword,"BLD",bldno)) q:bldno=""  d  q:$D(^TUPRN($J,"MATCHED"))
 ..s build=^UPRN("BLD",bldno)
 ..I '$$mcount^UPRNU($p(tbuild," ",2,10),$p(build," ",2,10)) q
 ..D:$$match29a(tpost,tstreet,tbno,build,tflat)
 q $G(^TUPRN($J,"MATCHED"))
match30(tpost,tstreet,tbno,tbuild,tflat)          ;
 ;Checks building flat and post code and works back
 i tbuild="" q 0
 i tflat'?1n.n1" "2l.e q 0
 n thouse,xbuild
 s thouse=$p(tflat," ",2,10)
 s xbuild=thouse
 for  s xbuild=$O(^UPRNX("X3",xbuild)) q:(xbuild'[thouse)  d  Q:$G(^TUPRN($J,"MATCHED"))
 .i xbuild[tbuild d  q:$G(^TUPRN($J,"MATCHED"))
 ..d:$$match30a(tpost,tstreet,tbno,xbuild,$p(tflat," ",1))
 q $G(^TUPRN($J,"MATCHED"))
 ;
match30a(tpost,tstreet,tbno,tbuild,tflat)        ;
 n flat
 s flat=""
 for  s flat=$O(^UPRNX("X3",tbuild,flat)) q:flat=""  d  q:$G(^TUPRN($J,"MATCHED"))
 .i '$$fuzflat^UPRNU(flat,tflat) q
 .d:$$match29a(tpost,tstreet,tbno,tbuild,flat)
 q $G(^TUPRN($J,"MATCHED"))
match31(tpost,tstreet,tbno,tbuild,tflat)          ;
 ;Flat in street number, wrong post code, levenshtein street
 i tstreet=""!(tbno="")!(tflat'="") q 0
 
 s $p(matchrec,",",1)=""
 n word,sword,strno
 s word=$p(tstreet," "),sword=word
 s sword=""
 for  s sword=$O(^UPRNW("SFIX",word,sword)) q:sword=""  d  I $D(^TUPRN($J,"MATCHED")) Q
 .s strno=""
 .for  s strno=$O(^UPRNX("X.W",sword,"STR",strno)) q:strno=""  d  q:$D(^TUPRN($J,"MATCHED"))
 ..s street=^UPRN("STR",strno)
 ..I '$$mcount^UPRNU($p(adstreet," ",2,10),$p(street," ",2,10)) q
 ..I '$D(^UPRNX("X3",street,tbno*1)) q
 ..D:$$match32(tpost,street,tbno,tbuild,tflat)
 Q $G(^TUPRN($J,"MATCHED"))
 
match32(tpost,street,tbno,tbuild,flat)  ;Number contains flat equivalent
 s post=""
 for  s post=$O(^UPRNX("X3",street,tbno*1,post)) q:post=""  d  Q:$G(^TUPRN($J,"MATCHED"))
 .q:post=tpost
 .s $p(matchrec,",",1)=$$nearpost(post,adpost)
 .i $p(matchrec,",",1)="" q
 .I tbuild="",flat="" d
 ..s build=""
 ..for  s build=$O(^UPRNX("X5",post,street,tbno*1,build)) q:build=""  d  q:$g(^TUPRN($J,"MATCHED"))
 ...i $D(^UPRNX("X5",post,street,tbno*1,build,tbno)) d
 ....s ALG=ALG_"match32aa"
 ....s $p(matchrec,2,5)="Se,Ne,Bi,Fe"
 ....s matched=$$setuprns("X5",post,street,tbno*1,build,tbno)
 .s flat=""
 .for  s flat=$O(^UPRNX("X5",post,street,tbno*1,tbuild,flat)) q:flat=""  d
 ..i $$fbno(tbno,flat) d
 ...s $p(matchrec,",",2,5)="Sl,Ne,Be,Fe"
 ...S ALG=ALG_"match32ab"
 ...s matched=$$setuprns("X5",post,street,tbno*1,tbuild,flat) 
 Q $G(^TUPRN($J,"MATCHED"))
 
 
match29a(tpost,tstreet,tbno,tbuild,tflat)        ;
 ;Building flat index, very approx post code, street match, any number
 n build,flat,bno,post,street,depth,buildroad
 i '$d(^UPRNX("X3",tbuild,tflat)) q 0
 s buildroad=$$isroad^UPRNA(tbuild)
 s $p(matchrec,",",4,5)="Be,Fe"
 s post=""
 for  s post=$O(^UPRNX("X3",tbuild,tflat,post)) q:post=""  d  q:$G(^TUPRN($J,"MATCHED"))
 .q:post=tpost
 .s matchrec=$$nearpost(post,adpost)
 .i matchrec="" q
 .s uprn=""
 .for  s uprn=$O(^UPRNX("X3",tbuild,tflat,post,uprn)) q:uprn=""  d  Q:matched
 ..s table=""
 ..for  s table=$O(^UPRNX("X3",tbuild,tflat,post,uprn,table)) q:table=""  d  Q:matched
 ...s key=""
 ...for  s key=$O(^UPRNX("X3",tbuild,tflat,post,uprn,table,key)) q:key=""  d  q:matched
 ....D GETADR^UPRNU(uprn,table,key,.flat,.build,.bno,.depth,.street,.deploc,.loc,.town,.lpost,.org)
 ....I buildroad,street=tbuild,bno=tflat,tbno="",flat="" d  q
 .....s $p(matchrec,",",2,5)="Si,Ni,Be,Fe"
 .....s ALG=ALG_"match29ab"
 .....s matched=$$set(uprn,table,key)
 ....S $p(matchrec,",",2)=""
 ....I $$contains^UPRNU(depth,street,tstreet) d
 .....s $p(matchrec,",",2)="Se"
 .....s $p(matchrec,",",3)="Ni"
 .....i $$mno1(tbno,bno,.approx) d
 ......s $p(matchrec,",",3)="N"_approx
 .....s ALG=ALG_"match29"
 .....s matched=$$set(uprn,table,key)
 ....i street=tstreet d
 .....s $p(matchrec,",",2)="Se"
 .....i tbno="",bno'="" s $p(matchrec,",",3)="Ni"
 .....e  d
 ......i tbno'="",bno="" s $p(matchrec,",",3)="Nd"
 ......e  d
 .......i tbno'="",bno'="",tbno'=bno s $p(matchrec,",",3)="Nx"
 .......e  s $p(matchrec,",",3)="Ne"
 .....s ALG=ALG_"match29a"
 .....s matched=$$set(uprn,table,key)
 q $G(^TUPRN($J,"MATCHED"))
 
 ;
match33(tpost,tstreet,tbno,tbuild,tflat)  ;Flat is number, partical building
 i '$D(^UPRNX("X5",tpost,tstreet,tflat)) q 0
 I tflat="" q 0
 n build
 s build=""
 for  s build=$O(^UPRNX("X5",tpost,tstreet,tflat,build)) q:build=""  d  Q:$G(^TUPRN($J,"MATCHED"))
 .i '$$equiv^UPRNU(tbuild,build) d match33a q
 .i $$partial^UPRNU(tbuild,build) d match33a q
 Q $G(^TUPRN($J,"MATCHED"))
match33a ;
 n matched,flat
 s matched=0
ds33a i tflat=""  d  q:matched
 .s rest=$$lt^UPRNL($$tr^UPRNL(tbuild,build,""))
 .s flat=""
 .for  s flat=$O(^UPRNX("X5",tpost,tstreet,tflat,build,flat)) q:flat=""  d  q:matched
 ..i $$eqflat^UPRNB(rest,flat) d
 ...s matchrec="Pe,Se,Ne,Bp,Fp"
 ...s ALG=ALG_"match33a"
ds33ax ...s matched=$$setuprns("X5",tpost,tstreet,tflat,build,flat)
 i '$d(^UPRNX("X5",tpost,tstreet,tflat,build,"")) q
 s matchrec="Pe,Se,Ne,Bp,Fe"
 s ALG=ALG_"match33"
 s matched=$$setuprns("X5",tpost,tstreet,tflat,build,"")
 q
 
 
match34(tpost,tstreet,tbno,tbuild,tflat)  ;
 ;number wandered into building ignore building
 I $D(^UPRNX("X5",tpost,tstreet,tbno,tbuild,tflat)) d  q 1
 .s build=tbuild
 .s matchrec="Pe,Se,Ne,Be,Fe"
 .d match34a
 i $D(^UPRNX("X5",tpost,tstreet,tbno,"",tflat)) d  q 1
 .s build=""
 .s matchrec="Pe,Se,Ne,Bi,Fe"
 .d match34a
 q 0
match34a ;
 S ALG=ALG_"match34"
 s matched=$$setuprns("X5",tpost,tstreet,tbno,build,tflat)
 q
match35(tpost,tstreet,tbno,tbuild,tflat)  ;Number contains flat equivalent
 I tflat'?1n.n1l q 0
 n bno,flat
 s bno=tflat*1
 s flat=$p(tflat,tflat*1,2)
 s post=""
 for  s post=$O(^UPRNX("X3",tbuild,bno,post)) q:post=""  d  Q:$G(^TUPRN($J,"MATCHED"))
 .q:post=tpost
 .i '$d(^UPRNX("X5",post,tbuild,bno,"",flat)) q
 .s $p(matchrec,",",1)=$$nearpost(post,adpost)
 .i $p(matchrec,",",1)="" q
 .s $p(matchrec,",",2,5)="Se,Ne,Bi,Fe"
 .s ALG=ALG_"match35"
 .s matched=$$setuprns("X5",post,tbuild,bno,"",flat)
 q $G(^TUPRN($J,"MATCHED"))
 
 
match36(tpost,tstreet,tbno,tbuild,tflat)  ;Building is mispelled street
 i tstreet'=""!(tbno'="") q 0
 s build=$p(tbuild," ")_" "
 for  s build=$O(^UPRNX("X3",build)) q:($p(build," ")'=$p(tbuild," "))  d  q:$G(^TUPRN($J,"MATCHED"))
 .i '$D(^UPRNX("X5",tpost,build,tflat,"","")) q
 .i '$$levensh^UPRNU(build,tbuild) q
 .s $p(matchrec,",",2,5)="Sl,Ne,Be,Fe"
 .S ALG=ALG_"match36"
 .s matched=$$setuprns("X5",tpost,build,tflat,"","")
 Q $G(^TUPRN($J,"MATCHED"))
 
match37(tpost,tstreet,tbno,tbuild,tflat)  ;Either Number contains flat equivalent
 ;Or skip number
 n bno,build,matched
 i tbuild=""!(tbno="") q 0
 n var
 s matched=0
 f var="tbuild","adpbuild" d  Q:matched
 .I $D(^UPRNX("X5",tpost,tstreet,"",@var,tflat)) d  q
 ..s matchrec="Pe,Se,Nd,Be,Fe"
 ..s ALG=ALG_"match37a"
 ..s matched=$$setuprns("X5",tpost,tstreet,"",@var,tflat)
 i matched q 1
 i tflat'="" q 0
 s bno=""
 for  s bno=$O(^UPRNX("X5",tpost,tstreet,bno)) q:bno=""  d
 .s build=$p(tbuild," ")_" "
 .for  s build=$O(^UPRNX("X5",tpost,tstreet,bno,build)) q:($p(build," ")'=$p(tbuild," ")!(build=""))  d  q:$G(^TUPRN($J,"MATCHED"))
 ..i '$D(^UPRNX("X5",tpost,tstreet,bno,build,tbno)) q
 ..s $p(matchrec,",",1,5)="Pe,Se,Ni,Bp,Fi"
 ..s ALG=ALG_"match37"
 ..s matched=$$setuprns("X5",tpost,tstreet,bno,build,tbno)
 q $G(^TUPRN($J,"MATCHED"))
 
match38(tpost,tstreet,tbno,tbuild,tflat)  ;close number, null building and flat
 n matched
 s matched=0
 i tbuild'=""!(tflat'="") q 0
 I '$d(^UPRNX("X5",tpost,tstreet)) q 0
 n near,dir,near1,near2,near3
 I $D(^UPRNX("X3",tstreet,tbno)) d  i matched q 1
 .s post=""
 .for  s post=$O(^UPRNX("X3",tstreet,tbno,post)) q:post=""  d  q:matched
 ..i post=tpost q
 ..s near=$$nearpost(post,tpost,1)
 ..q:near=""
 ..I $D(^UPRNX("X5",post,tstreet,tbno,tbuild,tflat)) d
 ...s ALG=ALG_"match1e"
 ...s matchrec=near_",Se,Ne,Be,Fe"
 ...s matched=$$setuprns("X5",post,tstreet,tbno,tbuild,tflat)
 I tbno="" q 0
 s near=$O(^UPRNX("X5",tpost,tstreet,tbno),-1)
 s near1=$O(^UPRNX("X5",tpost,tstreet,tbno))
 i tbno?1n.n1l,near?1n.n,near1'?1n.n1l d
 .s near=$O(^UPRNX("X5",tpost,tstreet,tbno*1),-1)
 .s near1=$O(^UPRNX("X5",tpost,tstreet,tbno*1))
 i near'=""!(near1'="") d
 .I near="",near1'="" s bno=near1 d match38a q
 .i near1="",near'="" s bno=near D match38a q
 .s dif1=tbno-near,dif2=near1-tbno
 .i dif1>dif2 s bno=near1 d match38a q
 .e  s bno=near d match38a q
 q $G(^TUPRN($J,"MATCHED"))
match38a ;
 s $p(matchrec,",",1,5)="Pe,Se,Ns,Be,Fe"
 s $p(ALG,"-",2)="match38"
 s matched=$$setuprns("X5",tpost,tstreet,bno,"","")
 q
 
match39(tpost,tstreet,tbno,tbuild,tflat)  ;close number, null building and flat
 i tbuild=""!(tflat="")!(tbno="") q 0
 i tflat'?1n.n q 0
 n build,flat
 I '$D(^UPRNX("X5",tpost,tstreet,tbno)) q 0
 s build=""
 for  s build=$O(^UPRNX("X5",tpost,tstreet,tbno,build)) q:build=""  d  q:$D(^TUPRN($J,"MATCHED"))
 .s flat=""
 .for  s flat=$O(^UPRNX("X5",tpost,tstreet,tbno,build,flat)) q:flat=""  d  Q:$D(^TUPRN($J,"MATCHED"))
 ..i flat[(" "_tflat) d
 ...s $p(matchrec,",",1,5)="Pe,Se,Ne,Bi,Fe"
 ...s ALG=ALG_"match39"
 ...s matched=$$setuprns("X5",tpost,tstreet,tbno,build,flat)
 Q $G(^TUPRN($J,"MATCHED"))
 
 
 ;
match40(tpost,tstreet,tbno,tbuild,tflat)  ;close number, null building and flat
 I '$D(^UPRNX("X5",tpost,tstreet,tflat)) q 0
 I $D(^UPRNX("X5",tpost,tstreet,tflat,"","")) d
 .s matchrec="Pe,Se,Ne,Bd,Fc"
 .s ALG=ALG_"match40"
 .s matched=$$setuprns("X5",tpost,tstreet,tflat,"","")
 Q $G(^TUPRN($J,"MATCHED"))
 
match41(tpost,tstreet,tbno,tbuild,tflat)  ;close number, null building and flat
 I tflat'=""!(tbuild'="") q 0
 n build
 s build=""
 for  s build=$O(^UPRNX("X5",tpost,tstreet,"",build)) q:build=""  d  q:$d(^TUPRN($J,"MATCHED"))
 .I '$D(^UPRNX("X5",tpost,tstreet,"",build,tbno)) q
 .s matchrec="Pe,Se,Ni,Bi,Fe"
 .s ALG=ALG_"match41"
 .s matched=$$setuprns("X5",tpost,tstreet,"",build,tbno)
 Q $G(^TUPRN($J,"MATCHED"))
        
 
match42(tpost,tstreet,tbno,tbuild,tflat)  ;street number/ building flat swap
 ;Drop number suffix, parse flat
 n xflat
 I '$D(^UPRNX("X5",tpost,tbuild,tflat*1,tstreet)) D match42a q $G(^TUPRN($J,"MATCHED"))
 i tbno?1n.n1l d
 .s xflat=$e(tbno,$l(tbno))_" "_(tbno*1)
 .I $D(^UPRNX("X5",tpost,tbuild,tflat*1,tstreet,xflat)) d
 ..s matchrec="Pe,Se,Nds,Be,Fe"
 ..s ALG=ALG_"match42"
 ..s matched=$$setuprns("X5",tpost,tbuild,tflat*1,tstreet,xflat)
 I tbno="",tflat?1n.n1l d
 .i $D(^UPRNX("X5",tpost,tbuild,tflat*1,tstreet)) d
 ..d flatlist(tpost,tbuild,tflat*1,tstreet,$e(tflat,$l(tflat)))
 Q $G(^TUPRN($J,"MATCHED"))
 
match42a ;
 i tflat'?1n.n1l q
 I '$D(^UPRNX("X5",tpost,tbuild,tflat*1,"")) q
 n suffix
 s suffix=$e(tflat,$l(tflat))
 D flatlist(tpost,tbuild,tflat*1,"",suffix)
 q
 
 
match43(tpost,tstreet,tbno,tbuild,tflat)  ;wrong post number wrong, part building
 i tflat=""!(tbno="") q 0
 i $l(tbuild," ")<2 q 0
 n build
 s build=tbuild
 for  s build=$O(^UPRNX("X3",build)) q:($e(build,1,$l(tbuild))'=tbuild)  d  q:$G(^TUPRN($J,"MATCHED"))
 .Q:'$D(^UPRNX("X3",build,tflat))
 .s post=""
 .for  s post=$O(^UPRNX("X3",build,tflat,post)) q:post=""  d  q:$d(^TUPRN($J,"MATCHED"))
 ..I post=tpost q
 ..s $p(matchrec,",")=$$nearpost(post,tpost)
 ..i $p(matchrec,",")="" q
 ..i '$D(^UPRNX("X5",post,tstreet,"",build,tflat)) q
 ..s ALG=ALG_"match43"
 ..s $p(matchrec,",",2,5)="Se,Nd,Be,Fe"
 ..s matched=$$setuprns("X5",post,tstreet,"",build,tflat)
 Q $G(^TUPRN($J,"MATCHED"))
 
match44(tpost,tstreet,tbno,tbuild,tflat)  ;number range parent uprn
 I tflat'="",tbuild'="",tstreet="",tbno="" d
 .s tstreet=tbuild
 .s tbno=tflat
 .s (tflat,tbuild)=""
 i tbno="" q 0
 s bno=""
 for  s bno=$O(^UPRNX("X5",tpost,tstreet,bno)) q:bno=""  d  q:$D(^TUPRN($J,"MATCHED"))
 .i bno=tbno,tbuild="",tflat="" d match44a q
 .i bno["-" i tbno'<$p(bno,"-")&(tbno'>$p(bno,"-",2)) d
 ..d match44a
 Q $G(^TUPRN($J,"MATCHED"))
 
match44a ;
 S build=$O(^UPRNX("X5",tpost,tstreet,bno,""))
 s flat=$O(^UPRNX("X5",tpost,tstreet,bno,build,""))
 s matchrec="Pe,Se,Ne,Bi,Fi"
ub3 s ALG=ALG_"match44"
 s matched=$$setuprns("X5",tpost,tstreet,bno,build,flat)
ub4 q
match6c(tpost,tstreet,tbno,tbuild,tflat)          ;
 ;There is a potential better match to ABP flat from building
 ;Make sure candidate flat/ building is null
 n uprn,table,key
 i tbuild'=""!(tflat'="") q 0
 ;Checks for match on ABP building and flat and post coce
 I '$D(^UPRNX("X3",tstreet,tbno,tpost)) q 0
 s uprn=$O(^UPRNX("X3",tstreet,tbno,tpost,""))
 ;Check there is only one possible match
 I $O(^UPRNX("X3",tstreet,tbno,tpost,uprn))'="" q 0
 s table=$O(^UPRNX("X3",tstreet,tbno,tpost,uprn,""))
 s key=$O(^UPRNX("X3",tstreet,tbno,tpost,uprn,table,""))
 s matchrec="Pe,S>BSi,N>F,B,F"
 S ALG=ALG_"match6c"
 s matched=$$set(uprn,table,key)
 q 1
 
match6b(tpost,tstreet,tbno,tbuild,tflat)          ;
 ;Match on flat, building street and near post code
 I '$D(^UPRNX("X2",tbuild,tstreet,tflat)) q 0
 s post=""
 for  s post=$O(^UPRNX("X2",tbuild,tstreet,tflat,post)) q:post=""  d  q:$d(^TUPRN($J,"MATCHED"))
 .q:post=tpost
 .s $p(matchrec,",",1)=$$nearpost(post,adpost)
 .i $P(matchrec,",",1)="" q
 .s $p(matchrec,",",2)="Se"
 .s $p(matchrec,",",4)="Be"
 .s $p(matchrec,",",5)="Fe"
 .i $d(^UPRNX("X2",tbuild,tstreet,tflat,post,tbno)) d
 ..s $p(matchrec,",",3)="Ne"
 .e  i tbno'="" q
 .i $p(matchrec,",",3)="" s $p(matchrec,",",3)="Ni"
 .n bno
 .s bno=$O(^UPRNX("X2",tbuild,tstreet,tflat,post,""))
 .s ALG=ALG_"match6b"
 .s matched=$$setuprns("X2",tbuild,tstreet,tflat,post,bno)
 q $d(^TUPRN($J,"MATCHED"))
  
 
 
match7(tpost,tstreet,tbno,tbuild,tflat)          ;
 n i,q,try,near,matched
 ;Alternative post codes
 s matched=0,near=0
 f try=1:1:3 d  q:$d(^TUPRN($J,"MATCHED"))
 s post=""
 for  s post=$O(^UPRNX("X3",tstreet,tbno,post)) q:post=""  d  q:$d(^TUPRN($J,"MATCHED"))
 .q:post=tpost
 .s near=$$nearpost(post,adpost,try)
 .q:near=""
 .s $p(matchrec,",",1)=near
 .i $P(matchrec,",",1)=""!($p(matchrec,",",1)="Pp") q
 .s $p(matchrec,",",2,3)="Se,Ne"
 .I $D(^UPRNX("X5",post,tstreet,tbno,tbuild)) d  q:$d(^TUPRN($J,"MATCHED"))
 ..s $p(matchrec,",",4)="Be"
 ..d match7a(post,tstreet,tbno,tbuild,tflat) q:$D(^TUPRN($J,"MATCHED"))
 .S build=""
 .for  s build=$O(^UPRNX("X5",post,tstreet,tbno,build)) q:build=""  d  Q:$D(^TUPRN($J,"MATCHED"))
 ..q:build=tbuild
 ..i $$levensh^UPRNU(build,tbuild) D  Q:$D(^TUPRN($J,"MATCHED"))
 ...S $p(matchrec,",",4)="Bl"
 ...d match7a(post,tstreet,tbno,build,tflat)
 .s matches=$$match8(post,tstreet,tbno,tbuild,tflat)
 i $G(^TUPRN($J,"MATCHED"))>1 d prefer
 
 q $g(^TUPRN($J,"MATCHED"))
match7a(post,street,bno,build,tflat)   ;
 i $D(^UPRNX("X5",post,street,bno,build,tflat)) d  q
 .s $p(matchrec,",",5)="Fe"
 .s ALG=ALG_"match7aa"
 .s matched=$$setuprns("X5",post,street,bno,build,tflat)
 i $$mflat(post,street,bno,build,tflat,.flat,.approx) d
 .s $p(matchrec,",",5)="F"_approx
 .s ALG=ALG_"match7ab"
 .s matched=$$setuprns("X5",post,street,bno,build,flat)
 q
 
nearpost(post,adpost,hownear)        ;How close is post code
 n near
 s near=""
 i adpost="" q ""
 i '$$inpost(adpost,qpost) q ""
 i $g(hownear)=1 d  q near
 .i $$sector(post,.endpost)=$$sector(adpost,.endad) d
 ..i $$levensh^UPRNU(endpost,endad,2)<2 d
 ...s near="Pl"
 i $g(hownear)=2 d  q near
 .i $$sector(post,.endpost)=$$sector(adpost,.endad) d
 ..i $$levensh^UPRNU(endpost,endad,2,2)<2 d
 ...s near="Pl"
 i $$levensh^UPRNU(post,adpost,5) d  q near
 .s near="Pl"
 i $$area(post)=$$area(adpost) q "Pp"
 e  q ""
 
prefer ;
 n prefer
 s prefer=0
 s current=0
 s (uprn,table,key)=""
 for  s uprn=$O(^TUPRN($J,"MATCHED",uprn)) q:uprn=""  d
 .i $P(^UPRN("U",uprn),"~",3)'=8 d
 ..s current=1
 for  s uprn=$O(^TUPRN($J,"MATCHED",uprn)) q:uprn=""  d
 .i $P(^UPRN("U",uprn),"~",3)=8,current D  Q
 ..K ^TUPRN($J,"MATCHED",uprn) s ^TUPRN($J,"MATCHED")=^TUPRN($J,"MATCHED")-1 Q
 .s table=""
 .for  s table=$O(^TUPRN($J,"MATCHED",uprn,table)) q:table=""  d
 ..s key=""
 ..for  s key=$O(^TUPRN($J,"MATCHED",uprn,table,key)) q:key=""  d
 ...s lprec=^(key)
 ...D GETADR^UPRNU(uprn,table,key,.flat,.build,.bno,.depth,.street,.deploc,.loc,.town,.post,.org)
 ...i flat=adflat,build=adbuild,depth=adepth,street=adstreet,bno=adbno d
 ....s pref=$s($e(post,1,3)=$e(adpost,1,3):0,1:1)
 ....s prefer(pref,uprn,table,key)=^TUPRN($J,"MATCHED",uprn,table,key)
 ....s prefer(pref,uprn,table,key,"A")=^TUPRN($J,"MATCHED",uprn,table,key,"A")
 ....s prefer=prefer+1
 i '$g(prefer) Q
 K ^TUPRN($j,"MATCHED")
 s pref=$o(prefer(""))
 s uprn=$o(prefer(pref,""))
 s table=""
 for  s table=$O(prefer(pref,uprn,table)) q:table=""  d
 .s key=""
 .for  s key=$O(prefer(pref,uprn,table,key)) q:key=""  d
 ..s ALG=prefer(pref,uprn,table,key,"A")
 ..s ^TUPRN($J,"MATCHED")=1
 ..S ^TUPRN($J,"MATCHED",uprn,table,key)=prefer(pref,uprn,table,key)
 ..S ^TUPRN($J,"MATCHED",uprn,table,key,"A")=ALG
 Q
 
match8(post,tstreet,tbno,tbuild,tflat)         ;
 ;Called from match7
 ;Matches using X3
 ;Assumes flat and number match
 ;straight match
 n matched
 s matched=0
 N build,street,bno,flat,flatlist
 I $D(^UPRNX("X5",post,tstreet,tbno,tbuild,tflat)) d
 .s $p(matchrec,",",3,5)="Ne,Be,Fe"
 .s $p(ALG,"-",2)="match8"
 .s matched=$$setuprns("X5",post,tstreet,tbno,tbuild,tflat) 
 i $g(^TUPRN($J,"MATCHED")) Q $G(^TUPRN($J,"MATCHED"))
 
 S $p(matchrec,",",3)="Ne"
 i tflat'="" I $D(^UPRNX("X5",post,tstreet,tbno,tbuild)) d
 .d flatlist(post,tstreet,tbno,tbuild,tflat)
        
 I $G(^TUPRN($J,"MATCHED")) Q 1
 ;Looping through UPRNs for match
 s uprn=""
 for  s uprn=$O(^UPRNX("X3",tstreet,tbno,post,uprn)) q:uprn=""  d  Q:matched
 .s table=""
 .for  s table=$O(^UPRNX("X3",tstreet,tbno,post,uprn,table)) q:table=""  d  Q:matched
 ..s key=""
 ..for  s key=$O(^UPRNX("X3",tstreet,tbno,post,uprn,table,key)) q:key=""  d  q:matched
 ...s lprec=^(key)
 ...D GETADR^UPRNU(uprn,table,key,.flat,.build,.bno,.depth,.street,.deploc,.loc,.town,.post,.org)
 ...S $p(matchrec,",",3)=$s(bno=tbno:"Ne",bno=""&(tbno'=""):"Nd",1:"Ni")
 ...i build="",tbuild="" d  q
 ....s $p(matchrec,",",4)="Be"
 ....i flat="",tflat="" d  q
 .....s $p(matchrec,",",5)="Fe"
 .....s ALG=ALG_"match8a"
 .....s matched=$$set(uprn,table,key) q
 ....i $$mflat2(flat,tflat) d  q
 .....s $p(matchrec,",",5)="Fp"
 .....s ALG=ALG_"match8b"
 .....s matched=$$set(uprn,table,key)
 ...Q
 ...i $$equiv^UPRNU(build,tbuild) d  q
 ....s $p(matchrec,",",4)="Bl"
 ....i $$mflat1(tflat,flat,.approx) d
 .....s $p(matchrec,",",5)="F"_approx
 .....s ALG=ALG_"match8c"
 .....s matched=$$set(uprn,table,key)
 ...s $p(matchrec,",",4)=""
 ...i $$equiv^UPRNU(build,tstreet) d
 ....s $p(matchrec,",",4)="Bl"
 ...I $$MPART^UPRNU(street,tbuild) d
 ....S $P(matchrec,",",2)="Sp"
 ...i $p(matchrec,",",4)="" q
 ...i tflat=bno,tbno=flat d
 ....s $p(matchrec,",",2)="Ne"
 ....s $p(matchrec,",",5)="Fe"
 ....S ALG=ALG_"match8e"
 ....s matched=$$set(uprn,table,key)
 Q $G(^TUPRN($J,"MATCHED"))
 
flatlist(post,tstreet,tbno,tbuild,tflat) ;Cycles through list of flats
 n matched,node
 s matched=0
 n flatlist,flat,offset
 s offset=0
 s node=$O(^UPRNX("X5",post,tstreet,tbno,tbuild,"base"))
 i node["base" d
 .i node["ground" s offset=0 q
 .s offset=1
 i tflat?1n.n d  q
 .s tflat=tflat-offset
 .s term=$G(^UPRNS("FLOORNUM",tflat))
 .i term'="" d
 ..s flat=$O(^UPRNX("X5",post,tstreet,tbno,tbuild,term))
 ..i flat[term d
 ...s $p(matchrec,",",2,5)="Se,Ne,Be,Fe"
 ...s ALG=ALG_"match8ax"
 ...s matched=$$setuprns("X5",post,tstreet,tbno,tbuild,flat)
 I tflat?1l d  q
 .s tflat=$c($a(tflat)-offset)
 .s term=$G(^UPRNS("FLOORCHAR",tflat))
 .i term'="" d
 ..s flat=$O(^UPRNX("X5",post,tstreet,tbno,tbuild,term))
 ..i flat[term d
 ...s $p(matchrec,",",2,5)="Se,Ne,Be,Fe"
 ...s ALG=ALG_"match8ax"
 ...s matched=$$setuprns("X5",post,tstreet,tbno,tbuild,flat)
 q
 
match5f(tpost,tstreet,tbno,tbuild,tflat) 
 ;Candidate has number with extension and flat number
 ;ABP has building number in building field with flat suffix
 i tstreet=""!(tbuild'="")!(tflat="")!(tbno="") q ""
 I $D(^UPRNX("X5",tpost,tstreet,"",tbno,"")) d
 .b
 .i $$flatsuff^UPRNU(tbno,tflat) d
 ..s matchrec="Pe,Se,Ne,Be,Fi"
 ..s ALG=ALG_"match5f"
 ..s matched=$$setuprns("X5",tpost,tstreet,"",tbno,"")
 Q $G(^TUPRN($J,"MATCHED"))
 
 
match6(tpost,tstreet,tbno,tbuild,tflat) 
 ;Suffix drop or ignore on number
 ;b
 n bno,build
 I tflat="",tbuild="" d  I $D(^TUPRN($J,"MATCHED")) Q 1
 .i $D(^UPRNX("X5",tpost,tstreet,"","",tbno)) d
 ..s matchrec="Pe,Se,Ne,Be,Fe"
 ..S ALG=ALG_"match6z"
 ..s matched=$$setuprns("X5",tpost,tstreet,"","",tbno)
 
 i $D(^UPRNX("X5",tpost,tstreet)) d
 .i tflat="",tbno?1n.n1l d  q:$D(^TUPRN($J,"MATCHED"))
 ..I $D(^UPRNX("X5",tpost,tstreet,tbno*1,tbuild)) d  q:$d(^TUPRN($J,"MATCHED"))
 ...d flatlist(tpost,tstreet,tbno*1,tbuild,$e(tbno,$l(tbno)))
 .s $p(matchrec,",",2)="Se"
 .s bno=""
 .for  s bno=$O(^UPRNX("X5",tpost,tstreet,bno)) q:bno=""  d  q:$d(^TUPRN($J,"MATCHED"))
DS101 ..i bno=(tbno*1) i $$match6c(tpost,tstreet,tbno,tbuild,tflat) q
 ..i $$mno1(tbno,bno,.approx) d
DS102 ...I $D(^UPRNX("X5",tpost,tstreet,bno,tbuild,tbno)) d  Q
DS103 ....s matchrec="Pe,Se,N&F,Be,Fe"
DS104 ....s ALG=ALG_"match6d"
DS105 ....s matched=$$setuprns("X5",tpost,tstreet,bno,tbuild,tbno) q
 ...I $D(^UPRNX("X5",tpost,tstreet,bno,tbuild,tflat)) d
 ....s matchrec="Pe,Se,N"_approx_",Be,Fe"
 ....s ALG=ALG_"match6"
 ....s matched=$$setuprns("X5",tpost,tstreet,bno,tbuild,tflat) q
 .I $D(^TUPRN($J,"MATCHED")) Q
 .I $D(^TUPRN($J,"MATCHED")) Q
 .s bno=""
 .for  s bno=$O(^UPRNX("X5",tpost,tstreet,bno)) q:bno=""  d  q:$d(^TUPRN($J,"MATCHED"))
 ..i tbno="",tbuild'="" d match6a q
 ..s $p(matchrec,",",3)=""
 ..i $$mno1(tbno,bno,.approx) do
 ...s $p(matchrec,",",3)="N"_approx
 ..i $p(matchrec,",",3)="" q
 ..i $D(^UPRNX("X5",tpost,tstreet,bno,tbuild)) d  q
 ...s $p(matchrec,",",4)="Be"
 ...i $$mflat(tpost,tstreet,bno,"",tflat,.flat,.approx) d  q
 ....s $p(matchrec,",",5)="F"_approx
 ....s ALG=ALG_"match6"
 ....s matched=$$setuprns("X5",tpost,tstreet,bno,"",flat)
 ..if tbuild'="" d
 ...I tflat'="" d
 ....i $$mflat(tpost,tstreet,bno,"",tflat,.flat,.approx) d
 .....s $p(matchrec,",",4)="Bi"
 .....s $p(matchrec,",",5)="F"_approx
ub11 .....s $p(ALG,"-",2)="match6a"
ub12 .....s matched=$$setuprns("X5",tpost,tstreet,bno,"",flat)
 q $G(^TUPRN($J,"MATCHED"))
 
match6a ;Supplementary match on building and either null number approx flat
 I '$D(^UPRNX("X5",tpost,tstreet,bno,tbuild)) q
 i $$mflat(tpost,tstreet,bno,tbuild,tflat,.flat,.approx) d
 .s $p(matchrec,",",4)="Be"
 .s $p(matchrec,",",5)="F"_approx
 .s $p(matchrec,",",3)="Si"
ub9 .s $p(ALG,"-",2)="match6aa"
ub10 .s matched=$$setuprns("X5",tpost,tstreet,bno,tbuild,flat)
 q
 ;Post code, street, number, flat, ignore building
match2d(tpost,tstreet,tbno,tbuild,tflat)          ;
 n matched
 s matched=0
 s build=$O(^UPRNX("X4",tpost,tstreet,tbno,tflat,""))
 i build="" q 0
 s matchrec="Pe,Se,Ne,Bi,Fe"
 s ALG="125-match2d"
 s matched=$$setuprns("X4",tpost,tstreet,tbno,tflat,build)
 q 1
 
match18(tpost,tstreet,tbno,tbuild,tflat,adloc) 
 ;Final run through for this post code, might need to go for parent
 n matched,front,back
 k flatlist
 s matched=0
 ;Check for flat range/number/building/street mismath
 d match18^UPRNB1(tpost,tstreet,tbno,tbuild,tflat)
 I $D(^TUPRN($J,"MATCHED")) Q 1
 s uprn=""
 for  s uprn=$O(^UPRNX("X1",tpost,uprn)) q:uprn=""  d  q:matched
 .s table=""
 .for  s table=$O(^UPRN("U",uprn,table)) q:table=""  d  q:matched
 ..s key=""
 ..for  s key=$O(^UPRN("U",uprn,table,key)) q:key=""  d  q:matched
 ...s rec=^(key)
 ...s flat=$p(rec,"~",1),build=$p(rec,"~",2)
 ...s bno=$p(rec,"~",3),depth=$p(rec,"~",4)
 ...s street=$p(rec,"~",5),deploc=$p(rec,"~",6)
 ...S loc=$p(rec,"~",7),town=$p(rec,"~",8)
 ...i adloc'="" i street=(tstreet_" "_adloc) s tstreet=street
 ...I tbuild=street,tbuild'="" d
 ....i tbno="",tflat?1n.n.l1" "1l.e,build=$p(tflat," ",2,10) d  q:matched
 .....I $D(^UPRNX("X5",tpost,street,"",$p(tflat," ",2,20),$p(tflat," "))) d
 ......s matchrec="Pe,Se,Ne,Be,Fe"
 ......S ALG=ALG_"match18au"
 ......s matched=$$set(uprn,table,key)
 ....i bno="",build="",$$mno1(tflat,flat) d 
 .....s matchrec="Pe,Se,Nd,Bd,Fe"
 .....s ALG=ALG_"match18z"
 .....s matched=$$set(uprn,table,key)
 ...i tbno="",tflat?1n.n.l1" "1l.e,street=$p(tflat," ",2,10) d  q:matched
 ....i $D(^UPRNX("X5",tpost,street,$p(tflat," "),"","")) d
 .....s $p(matchrec,",",1,5)="Pe,Se,Ne,Bi,Fe"
 .....s ALG=ALG_"match18az"
 .....s matched=$$set(uprn,table,key)
 ....I $D(^UPRNX("X5",tpost,street,$p(tflat," ")*1,"",$p(tflat," "))) d
 .....s $p(matchrec,",",1,5)="Pe,Se,Ne,Bi,Fe"
 .....s ALG=ALG_"match18ay"
 .....s matched=$$set(uprn,table,key)
 ...S pstreet=$$plural^UPRNU(street)
 ...i pstreet'=tstreet,tbuild="" d  q
 ....d match18a
 ....i $D(^TUPRN($J,"MATCHED")) s matched=1
 ...i tbuild'="",$$equiv^UPRNU(street,tbuild_" "_tstreet) d  q
 ....s matched=$$match18h()
 ...I tstreet'="",pstreet'="",tstreet'=pstreet d
 ....i tbno=bno,tflat'="",flat'="" d
 .....i build'="",tbuild'="" d
 ......i $$equiv^UPRNU(build,tbuild) d
 .......i $$mflat1(tflat,flat,.approx) d
 ........s $p(matchrec,",",2,5)="Si,Ne,Bl,F"_approx
 ........s ALG=ALG_"match18b"
 ........s matched=$$set(uprn,table,key)
 ...i $$roadmiss^UPRNU(tbuild,pstreet) d  q
 ....i tflat=bno,flat="",tbno="",build="" d
 .....s $p(matchrec,",",2,5)="Sp,Ne,Be,Fe"
 .....s ALG=ALG_"match18c"
 .....s matched=$$set(uprn,table,key)
 ...i tflat?1n.n1" "2l.e d
 ....i $p(tflat," ",1)=flat d
 .....i pstreet=tstreet d
 ......i $$equiv^UPRNU(build,$p(tflat," ",2,10)) d
 .......i tbno=bno s $p(matchrec,",",2,5)="Se,Ne,Be,Fe"
 .......i tbno'=bno s $p(matchrec,",",2,5)="Se,Ni,Be,Fe"
 .......s ALG=ALG_"match18c2"
 .......s matched=$$set(uprn,table,key)
 ...I tflat'="",$$equiv^UPRNU(build,tflat_" "_tbuild) d
 ....i $$equiv^UPRNU(loc,tstreet) d
 .....i bno="",tbno="" d
 ......s $p(matchrec,",",2,5)="Se,Ne,Be,Fe"
 ......s ALG=ALG_"match18d"
 ......s matched=$$set(uprn,table,key)
 ...i tbno'="",tbno=$p(build," "),tstreet=$p(build," ",2,10) d
 ....i flat=tflat d
 .....s $p(matchrec,",",1,5)="Pe,Sp,Np,Bp,Fe"
 .....s ALG=ALG_"match18da"
 .....s matched=$$set(uprn,table,key)
 ...i pstreet'=tstreet q
 ...s $p(matchrec,",",1,2)="Pe,Se"
 ...d match18c i matched q
 ...i bno="",flat="",tbuild="",build=(tflat_" "_tbno) d  q ;unit 6 tilia
 ....s $p(mathcrec,",",3,5)="Ne,Be,Fe"
 ....s ALG=ALG_"match18e"
 ....s matched=$$set(uprn,table,key)
 ...i bno="",flat="",tflat="",build=(tbno_" "_tbuild) d  q ; 75 ability
 ....s $p(matchrec,",",1,5)="Pe,Se,Ne,Be,Fe"
 ....s ALG=ALG_"match18f"
 ....s matched=$$set(uprn,table,key)
 ...i bno=tbno q  ;Already processed in match2
 ...;101 101a problem
 ...i build="",tbuild="" d  q
 ....s $p(matchrec,",",4)="Be"
 ....i $$fnsplit(tbno,bno,tflat,flat) d  q
 .....s $p(matchrec,",",3)="Ne"
 .....s $p(matchrec,",",4)="Be"
 .....s $p(matchrec,",",5)="Fe"
 .....s ALG=ALG_"match18g"
 .....s matched=$$set(uprn,table,key)
 ....I bno="",tflat="",tbno'="",$$mno1(tbno,flat) d  q
 .....s $p(matchrec,",",4,5)="Be,Fe"
 .....s ALG=ALG_"match18h"
 .....s matched=$$set(uprn,table,key)
 ....i flat="",tflat="",bno*1=(tbno*1) d
 .....s $p(matchrec,",",5)="Fe"
 .....s $p(matchrec,",",3)=$s(tbno?1n.n1l:"Nds",1:"Nis")
 .....s ALG=ALG_"match18i"
 .....s matched=$$set(uprn,table,key)
 ....i tbno*1=(bno*1),tflat'="",flat'="" d
 .....s flatlist(flat)=uprn_"~"_table_"~"_key
 ....i tbno*1=(bno*1),tflat'="",tflat=flat d  q
 .....s $p(matchrec,",",3)="Nds"
 .....s $p(matchrec,",",4,5)="Be,Fe"
 .....s ALG=ALG_"match18j"
 .....s matched=$$set(uprn,table,key)
 ...I build=""!(tbuild="") q
 ...i $$MPART^UPRNU(build,tbuild) d
 ....i flat=tflat,tbno="",bno'="" d  q
 .....s $p(matchrec,",",3,5)="Ni,Bp,Fe"
 .....s $p(ALG,"-",2)="match18k"
 .....s matched=$$set(uprn,table,key)
 ....i flat=tflat,tbno=bno d
 .....s $p(matchrec,",",4,5)="Bp,Fe"
 .....S ALG=ALG_"match18l"
 .....s matched=$$set(uprn,table,key)
 ....I tbno=flat,tflat=bno d
 .....s $p(matchrec,",",3)="Ne"
 .....s $p(matchrec,",",4)="Bp,Fe"
 .....S ALG=ALG_"match18m"
 .....s matched=$$set(uprn,table,key)
 i $D(^TUPRN($J,"MATCHED")) Q $G(^TUPRN($J,"MATCHED"))
 i $d(flatlist) d
 .i $$fmatch(tbno,.flatlist,.uprn,.table,.key) d
 ..s $p(matchrec,",",3)="Np"
 ..s $p(matchrec,",",4,5)="Be,Fe"
 ..s ALG=ALG_"match18n"
 ..s matched=$$set(uprn,table,key)
 Q $G(^TUPRN($J,"MATCHED"))
 
 
match18h()         ;Matched on building and street
 i bno=tflat,tbno="" d
 .s $p(matchrec,",",2)="Sp"
 .s $p(matchrec,",",3)="Ne"
 .s $p(matchrec,",",4)="Be"
 .s $p(matchrec,",",5)="Fe"
 .s ALG=ALG_"match18h"
 .s matched=$$set(uprn,table,key)
 Q $D(^TUPRN($J,"MATCHED"))
 
match18a         ;
 ;street building mix ups 1
 ;Building has slid into street
 n matched
 s matched=0
 i $$getfront^UPRNU(pstreet,tstreet,.front,.back) d match18z
 i flat=tbno,tflat="",bno="" d
 .i $$getback^UPRNU(tstreet,build_" "_street,.back) d  q
 ..i back'="",$D(^UPRNS("ROAD",back)) d
 ...s $p(matchrec,",",2,5)="Se,Ne,Be,Fe"
 ...s ALG=ALG_"match18aj"
 ...s matched=$$set(uprn,table,key)
 q 
match18z ;
 s xbuild=$s(tbuild="":front,1:tbuild_" "_front)
 i xbuild=build d
 .s $p(matchrec,",",2)="Se"
 .s $p(matchrec,",",4)="Be"
 .i tbno="",bno'="" s $p(matchrec,",",3)="Ni"
 .i bno="",tbno'="" s $p(matchrec,",",3)="Nd"
 .i bno=tbno s $p(matchrec,",",3)="Ne"
 .i bno'="",tbno'="" s $p(matchrec,",",3)="Ns"
 .i tflat'="",flat="" s $p(matchrec,",",5)="Fd"
 .i flat'="",tflat="" s $p(matchrec,",",5)="Fi"
 .i flat=tflat s $p(matchrec,",",5)="Fe"
 .;s ALG=ALG_"match18a"
 .;31/11/2020
 .s ALG=$P(ALG,"-")_"-match18a"
 .s matched=$$set(uprn,table,key)
 i $D(^TUPRN($J,"MATCHED")) Q
 
 ;street equivalent, building equivalent to street
 I $$equiv^UPRNU(pstreet,tstreet,8) d
 .I bno=tbno,flat="",tflat="" d
 ..i tbuild="" do
 ...i build'="",$$equiv^UPRNU(build,tstreet,8) d  q
 ....s $p(matchrec,",",2,5)="Sl,Ne,Bp,Fe"
 ....s ALG=ALG_"match18aa"
 ....s matched=$$set(uprn,table,key)
 ...i build="" d  Q
 ....s $p(matchrec,",",2,5)="Sl,Ne,Bp,Fe"
 ....s ALG=ALG_"match18ab"
 ....s matched=$$set(uprn,table,key)
 
 I $D(^TUPRN($J,"MATCHED")) Q
 n troad
 s troad=$$stripr^UPRNU(tstreet)
 I $$equiv^UPRNU(pstreet,troad,7) d
 .I bno=tbno,flat="",tflat="" d
 ..i tbuild="" do
 ...i build'="",$$equiv^UPRNU(build,tstreet,8) d  q
 ....s $p(matchrec,",",2,5)="Sl,Ne,Bp,Fe"
 ....s ALG=ALG_"match18ac"
 ....s matched=$$set(uprn,table,key)
 ...i build="" d  Q
 ....s $p(matchrec,",",2,5)="Sl,Ne,Bp,Fe"
 ....s ALG=ALG_"match18ad"
 ....s matched=$$set(uprn,table,key)
 i $d(^TUPRN($J,"MATCHED")) Q
 
 ;building is equivalent to street
 ;Doesnt have the right street
 ;Flat matches number?
 i build'="",$$equiv^UPRNU(build,tstreet) d  q
 .i bno="",tbno=flat d  q
 ..i tbuild="",flat="",tflat="" d  q:matched
 ...s $p(matchrec,",",2,5)="Si,Ni,Bl,Fe"
 ...s ALG=ALG_"match18ae"
 ...s matched=$$set(uprn,table,key)
 ..i flat'=tbno q
 ..s $p(matchrec,",",2)="Si"
 ..s $p(matchrec,",",3)="Ne"
 ..s $p(matchrec,",",4)="Be"
 ..s $p(matchrec,",",5)="Fe"
 ..s ALG=ALG_"match18af"
 ..s matched=$$set(uprn,table,key)
 .i bno'="",tbno'="" d  Q:matched
 ..i flat'=tbno q
 ..s $p(matchrec,",",2)="Si"
 ..s $p(matchrec,",",3)="Ni"
 ..s $p(matchrec,",",4)="Be"
 ..s $p(matchrec,",",5)="Fe"
 ..s ALG=ALG_"match18ag"
 ..s matched=$$set(uprn,table,key)
 .I flat=tflat,flat'="" d
 ..s $p(matchrec,",",2)="Si"
 ..i bno="",tbno'="" s $p(matchrec,",",3)="Nd"
 ..i tbno="",bno'="" s $p(matchrec,",",3)="Ni"
 ..I bno=tbno s $p(matchrec,",",3)="Ne"
 ..s $p(matchrec,",",4,5)="Bl,Fe"
 ..S ALG=ALG_"match18ah"
 ..s matched=$$set(uprn,table,key)
 
 ;first part of streets match, building has second part
 I $P(pstreet," ")=$p(tstreet," ") d
 .s back=$p(tstreet," ",2,10)
 .I back'="",build'="",build[back d
 ..i bno=tbno,flat=tflat d
 ...s $p(matchrec,",",2)="Sp"
 ...s $p(matchrec,",",3)="Ne"
 ...s $p(matchrec,",",4)="Bp"
 ...s $p(matchrec,",",5)="Fe"
 ...s ALG=ALG_"match18ai"
 ...s matched=$$set(uprn,table,key)
 
 q
 
match18c ;
 i tflat'=""!(tbuild'="") q
 I street'=tstreet q
 I tbno?1n.n1l,tbno*1=(bno*1),flat=$e(tbno,$l(tbno)) d
 .s matchrec="Pe,Se,Ne,Bi,Fe"
 .s ALG=ALG_"match18at"
 .s matched=$$set(uprn,table,key)
 Q
fbno(bno,flat)     ;matches a flat floor to a suffix
 n letter
 s letter=$p(bno,bno*1,2)
 i letter="" q 0
 i letter=flat q 1
 i $d(^UPRNS("FLOOR",$P(flat," flat"),letter)) q 1
 q 0
 
fmatch(tbno,flatlist,uprn,table,key)        ;
 n letter,matched
 s matched=0
 i tbno?1n.n1l d
 .s letter=$p(tbno,tbno*1,2)
 .i letter="a" d  q:matched
 ..i $$floor("basement") d  q
 ...d mfloor("basement")
 ..i $$floor("ground") d  q
 ...d mfloor("ground")
 ..i $$floor("first") d  q
 ...d mfloor("first")
 .i matched q
 .i letter="b" d  q:matched
 ..i $$floor("basement") d  q
 ...i $$floor("ground") d  q
 ....d mfloor("ground")
 ....s matched=1
 ..i $$floor("ground") d  q
 ...i $$floor("first") d  q
 ....d mfloor("first")
 ....s matched=1
 ..i $$floor("first") d  q
 ...i $$floor("second") d  q
 ....d mfloor("second")
 ....s matched=1
 i tflat?1n.n d
 .s offset=0
 .i $o(flatlist("base"))["base" s offset=1
 .s tflat=tflat-offset
 .i tflat=0,$o(flatlist("ground"))["ground" d  q
 ..d mfloor($o(flatlist("ground")))
 ..s matched=1
 .i tflat=1,$o(flatlist("first"))["first" d  q
 ..d mfloor($o(flatlist("first")))
 ..s matched=1
 .i tflat=2,$o(flatlist("second"))["second" d  q
 ..d mfloor($o(flatlist("second")))
 ..s matched=1
 .i tflat=3,$o(flatlist("third"))["third" d  q
 ..d mfloor($o(flatlist("third")))
 ..s matched=1
 q matched
 
mfloor(term)       ;
 s floor=""
 for  s floor=$o(flatlist(floor)) q:floor=""  d
 .i floor[term d
 ..s uprn=$p(flatlist(floor),"~"),table=$p(flatlist(floor),"~",2),key=$p(flatlist(floor),"~",3)
 q
 
floor(term)        ;Scans for floor in a term
 n floor,found
 s floor="",found=0
 for  s floor=$o(flatlist(floor)) q:floor=""  d
 .i floor[term s found=1
 q found
 
fnsplit(tbno,bno,tflat,flat) ;Number includes flat
 n matched
 s matched=0
 i bno'="",tbno'="",flat=tbno,(tbno*1)=bno q 1 ;
 i flat?1l,$e(tbno,$l(tbno))=flat,bno=(tbno*1) q 1
 q 0
match11(tpost,tstreet,tbno,tbuild,tflat,lastchan,tloc) 
 ;Cycles through all uprns looking for fuzzy streets,odd buildings
 n matched,front,back,flatlist,xstreet,xbuild,lenstreet
 s matched=0
 i $g(lastchance) d
 .s xstreet=""
 .s lenstreet=$l(tstreet," ")
 .i lenstreet<3 q
 .I lenstreet,tbuild="" d
 .s xstreet=$p(tstreet," ",lenstreet-1,lenstreet)
 .s xbuild=$p(tstreet," ",1,lenstreet-2)
 K ^UPRN("Considered")
 s uprn=""
 for  s uprn=$O(^UPRNX("X1",tpost,uprn)) q:uprn=""  d  Q:matched
 .s table=""
 .for  s table=$O(^UPRN("U",uprn,table)) q:table=""  d  q:matched
 ..s key=""
 ..for  s key=$O(^UPRN("U",uprn,table,key)) q:key=""  d  q:matched
 ...s rec=^(key)
 ...s flat=$p(rec,"~",1),build=$p(rec,"~",2)
 ...s bno=$p(rec,"~",3),depth=$p(rec,"~",4)
 ...s street=$p(rec,"~",5),deploc=$p(rec,"~",6)
 ...S loc=$p(rec,"~",7)
 ...I tbno?1n.n,tflat?1l,bno=(tbno_tflat) d match11d  q:matched
 ...I tbno?1n.n,tflat?1l,bno=tbno,$p(flat," ")=tflat d match11e q:matched
 ...i flat="",$L(build," ")>1,$p(build," ",$l(build," "))?1n.n.e d
 ....s flat=$p(build," ",$l(build," "))
 ....s build=$p(build," ",1,$l(build," ")-1)
 ...I $g(lastchance) d match11c q
 ...i flat=tflat,bno=tbno d  q:matched
ds901 ....i tbuild'=""&(build'="") d
ds902 .....I tbuild[build,$$equiv^UPRNU($p(tbuild,build_" ",2),street) d match11z q
 ...i street=tstreet d  q:matched
 ....s $p(matchrec,",",2)="Se"
 ....d match11f  q:matched
 ....I tbno="",'$D(^UPRNX("X5",tpost,tstreet,"")) d
 .....i flat=tflat
 .....i $l(build," ")>1,build[tbuild!(tbuild[build) d
 ......d match11g
 ...i $$equiv^UPRNU(street,tstreet) d  q:matched
 ....s $p(matchrec,",",2)="Sl"
 ....d match11f i matched q
 ...I tbno="",tstreet'="" d
 ....i bno=$G(^UPRNS("NUMBERS",$p(tstreet," "))) d
 .....i street=$p(tstreet," ",2,10) d
 ......s tbno=bno
 ......s tstreet=street
 ...I tflat?1l I bno=(tbno_tflat) s tflat="",tbno=bno
 ...I bno'=tbno q
 ...s pstreet=$$PLURAL^UPRNU(street)
 ...i $$getfront^UPRNU(pstreet,tstreet,.front,.back) d  q
 ....s xbuild=$s(tbuild="":front,1:tbuild_" "_front)
 ....i build=xbuild d
 .....s matched=$$match11a(uprn,table,key)
 ...i $$getback^UPRNU(pstreet,tstreet,.back) d  q
 ....i back'="",$D(^UPRNS("ROAD",back)) d
 .....s matched=$$match11a(uprn,table,key)
 q matched
consider(tstreet,street)   ;
 i tstreet=""!(street="") q
 n pstreet,ptstreet
 I tstreet=street d  q
 .s ^UPRNT("Match",street,tstreet)=1
 s pstreet=$$plural^UPRNU(street)
 s ptstreet=$$plural^UPRNU(tstreet)
 i ptstreet=pstreet d  q
 .s ^UPRNT("Match",street,tstreet)=1
 i $$equiv^UPRNU(street,tstreet) d  q
 .S ^UPRNT("Match",street,tstreet)=2
 i $$MPART^UPRNU(street,tstreet,1) d  q
 .S ^UPRNT("Match",street,tstreet)=3
 i $$getfront^UPRNU(pstreet,ptstreet,.front,.back) d  q
 .S ^UPRNT("Match",street,tstreet)=4
 .S ^UPRNT("Match",street,tstreet,"Front")=front
 i $$getback^UPRNU(pstreet,ptstreet,.back) d  q
 .S ^UPRNT("Match",street,tstreet)=4
 .S ^UPRNT("Match",street,tstreet,"Back")=back
 S ^UPRNT("Considered",street,tstreet)=""
 Q
 
match11a(uprn,table,key)          ;from match11
 ;uses street
 ;bno,build,depth,flat already defined
 n matched
 s matched=0
 s $p(matchrec,",",2)="Sl"
 s $p(matchrec,",",3)="Ne"
 I tbuild=build,tflat=flat d  q 1
 .s $p(matchrec,",",4,5)="Be,Fe"
 .s ALG=ALG_"match11a"
 .s matched=$$set(uprn,table,key)
 i tbuild=build d  I $d(^TUPRN($J,"MATCHED")) Q 1
 .s matched=$$match11b()
 i tbuild'="",build'="" d  q $G(^TUPRN($J,"MATCHED"))
 .i $$equiv^UPRNU(build,tbuild) d
 ..s $p(matchrec,",",4)="Bl"
 ..s matched=$$match11b()
 .e  I $$MPART^UPRNU(build,tbuild,2) d
 ..s $p(matchrec,",",4)="Bp"
 ..s matched=$$match11b()
 i tbuild="",build="" d  q $G(^TUPRN($J,"MATCHED"))
 .s matched=$$match11b()
 I tbuild="",build'="" d
 .i $l(tflat," ")>2 d
 ..I $P(tflat," ",$l(tflat," ")-1,$l(tflat," "))?1n.n1" "1l d
 ...s tflat=$p(tflat," ",1,$l(tflat," ")-1)_$p(tflat," ",$l(tflat," "))
 ..i $p(tflat," ",$l(tflat," "))?1n.n.l d
 .i $$MPART^UPRNU(build,$p(tflat," ",1,$l(tflat," ")-1),1) d
 ..i $$mflat1($p(tflat," ",$l(tflat," ")),flat,.approx) d
 ...S matched=1
 ...s $p(matchrec,",",4,5)="Bp,F"_approx
 ...s ALG=ALG_"match11e"
 ...s matched=$$set(uprn,table,key)
 q matched
 
match11b()          ;
 n matched,swapflat
 s matched=0
 ;matches flat
 i tflat="",flat="" d  Q 1
 .s $p(matchrec,",",5)="Fe"
 .s ALG=ALG_"match11b"
 .s matched=$$set(uprn,table,key)
 .set matched=1
 s swapflat=tflat
 d swap^UPRNU(.swapflat)
 i swapflat'="",flat[$p(swapflat," ") d  q 1
 .s $p(matchrec,",",4)="Be"
 .s $p(matchrec,",",5)="Fp"
 .set ALG=ALG_"match11c"
 .s matched=$$set(uprn,table,key)
 i $$mflat1(tflat,flat,.approx) d
 .s $p(matchrec,",",5)="F"_approx
 .set ALG=ALG_"match11d"
 .s matched=$$set(uprn,table,key)
 .set matched=1
 q matched
 ;
match11z          ;
 s ALG=ALG_"match11bc"
 s $p(matchrec,",",2,5)="Se,Ne,Be,Fe"
 s matched=$$set(uprn,table,key)
 q
 
match11c ;
 i $$MPART^UPRNU(street,tstreet,1) d  q
 .i xstreet'="",street'="",$$levensh^UPRNU(street,xstreet) d  q:matched
 ..i build'="",$$levensh^UPRNU(build,xbuild) d   q
 ...i flat'=tbno q
 ...s ALG=ALG_"match11aaa"
 ...s matched=$$set(uprn,table,key)
 .i bno'=tbno q
 .s matched=$$match11a(uprn,table,key) Q
 q
match11d ;
 i flat'="" q
 i build[tbuild!(tbuild[build) d
 .s matchrec="Pe,Se,Ne,Be,Fe"
 .s ALG=ALG_"match11da"
 .s matched=$$set(uprn,table,key)
 q
 
match11e ;
 i '$$isfloor(tbuild) q
 s matchrec="Pe,Se,Ne,Be,Fe"
 s ALG=ALG_"match11ea"
 s matched=$$set(uprn,table,key)
 q
match11f ;Already matched pretty close
 i tbno?1n.n1l d
 .d flatlist(tpost,street,tbno*1,tbuild,$e(tbno,$l(tbno)))
 
 I $G(^TUPRN($J,"MATCHED")) S matched=1 Q
 I tbuild="",build="",bno="",tbno'="",tflat="" d  q:matched
 .i $$mflat1(tbno,flat,.approx) d  q
 ..s ALG=ALG_"match11fa"
 ..s $p(matchrec,",",3,5)="Ne,Be,F"_approx
 ..s matched=$$set(uprn,table,key)
 I bno=tbno d
 .i build=tbuild d
 ..i flat=tflat d  q
 ...s $P(ALG,"-",2)="match11fc"
 ...s matched=$$set(uprn,table,key)
 ..i $$vertok^UPRNU(tflat,flat) d
 ...s $P(ALG,"-",2)="match11fz"
 ...s matched=$$set(uprn,table,key)
 .i $$equiv^UPRNU(build,tbuild) d
 ..i $$mflat1(tflat,flat,.approx) d
 ...s $p(matchrec,",",2,5)="Ne,Be,F"_approx
 ...s ALG=ALG_"match11fb"
 ...s matched=$$set(uprn,table,key)
 q
match11g ;
 s ALG=ALG_"match11g"
 s matchrec="Pe,Se,Ni,Bp,Fe"
 s matched=$$setuprns("X5",tpost,tstreet,bno,build,tflat)
 q
isfloor(term)      ;Is a term a floor
 i $O(^UPRNS("FLOOR",$p(term," ")))[$p(term," ",1) q 1
 q 0
 
 
 
match17(tpost,tstreet,tbno,tbuild,tflat)          ;
 ;Number slipped into flat field
 i tbno="",tbuild="",tflat'="" d
 .i $p(tflat," ",$l(tflat," "))?1n.n.l d
 ..s tbno=$p(tflat," ",$l(tflat," "))
 ..s tflat=$p(tflat," ",0,$l(tflat," ")-1)
 ..s matches=$$match2(tpost,tstreet,tbno,tbuild,tflat)
 Q $G(^TUPRN($J,"MATCHED"))
 
 ;
match2c(tpost,tstreet,tbno,tbuild,tflat)   ;Fuzzy buulding
 ;Unit stratford / unite building
 ;If build the same find nearest flat
 ;If building partial flat must match
 n build,flat
 s build=""
 for  s build=$O(^UPRNX("X5",tpost,tstreet,tbno,build)) q:build=""  d  q:$D(^TUPRN($J,"MATCHED"))
 .i ($$equiv^UPRNU(build,tbuild)) d  q
 ..s $p(matchrec,",",3,4)="Se,Bl"
 ..d match2ca
 .I $$MPART^UPRNU(build,tbuild,1) D  q
 ..s $p(matchrec,",",4)="Bp"
 ..D match2ca
 
 i $d(^TUPRN($J,"MATCHED")) Q
DSM2 ;
 I $D(^TUPRN($J,"MATCHED")) Q
 ;Try for sibling, child or parent flat
 s build=""
 for  s build=$O(^UPRNX("X5",tpost,tstreet,tbno,build)) q:build=""  d  q:$D(^TUPRN($J,"MATCHED"))
 .i ($$equiv^UPRNU(build,tbuild)) d  q
 ..s $p(matchrec,",",4)="Bl"
 ..d match2cb
 .I $$MPART^UPRNU(build,tbuild) D  q
 ..s $p(matchrec,",",4)="Bp"
 ..D match2cb
 q
 
match2ca          ;
 i $d(^UPRNX("X5",tpost,tstreet,tbno,build,tflat)) d  q
 .s $p(matchrec,",",5)="Fe"
ub5 .S $p(ALG,"-",2)="match2ca"
ub6 .s matched=$$setuprns("X5",tpost,tstreet,tbno,build,tflat)
 s flat=""
 for  s flat=$O(^UPRNX("X5",tpost,tstreet,tbno,build,flat)) q:flat=""  d  q:$d(^TUPRN($J,"MATCHED"))
 .i $$mflat1(tflat,flat,.approx) d
 ..s $p(matchrec,",",5)="F"_approx
 ..S ALG=ALG_"match2caa"
 ..s matched=$$setuprns("X5",tpost,tstreet,tbno,build,flat)
 i tbuild?1n.n1" "1l.e d
 .i $D(^UPRNX("X5",tpost,tstreet,tbno,build,$p(tbuild," "))) d
 ..s ALG=ALG_"match2cab"
 ..S $P(matchrec,",",4,5)="Bp,Fp"
 ..s matched=$$setuprns("X5",tpost,tstreet,tbno,build,$p(tbuild," "))
 q
 
match2cb ;Allows an approximation on flat
 i $$mflat(tpost,tstreet,tbno,build,tflat,.flat,.approx) d
 .s $p(matchrec,",",5)="F"_approx
ub7 .S $p(ALG,"-",2)="match2cb"
ub8 .s matched=$$setuprns("X5",tpost,tstreet,tbno,build,flat)
 q
 
 ;
match2g1(tpost,tstreet,tbno,tflat)     ;
 n build
 s build=""
 for  s build=$O(^UPRNX("X5",tpost,tstreet,tbno,build)) q:build=""  d
 .I $D(^UPRNX("X5",tpost,tstreet,tbno,build,tflat)) d
 ..s matchrec="Pe,Se,Ne,Bi,Fe"
 ..s ALG=ALG_"-match2g1"
 ..s matched=$$setuprns("X5",tpost,tstreet,tbno,build,tflat)
 Q $G(^TUPRN($J,"MATCHED"))
 
match2g(tpost,tstreet,tbno,null,adbuild)         ;
 ;Already matched on street, number and null building
 ;Matches on a flat, might have a fuzzy match
 n matched,flat
 s matched=0
 i $D(^UPRNX("X5",tpost,tstreet,tbno,null,adbuild)) d
 .s $p(mathrec,",",4)="Be"
 .s $p(matchrec,",",5)="Fe"
 .s ALG=ALG_"match2g"
 .s matched=$$setuprns("X5",tpost,tstreet,bno,"",adbuild)
 
 I $D(^TUPRN($J,"MATCHED")) Q 1
 
 d swap^UPRNU(.tflat)
 s flat=$p(tflat," ")
 for  s flat=$o(^UPRNX("X5",tpost,tstreet,tbno,"",flat)) q:flat=""  q:(flat'[$p(tflat," "))  d  q:matched
 .i $$equiv^UPRNU(flat,adbuild) d
 ..s $p(matchrec,",",4)="Be"
 ..s $p(matchrec,",",5)="Fl"
 ..s ALG=ALG_"match2h"
 ..s matched=$$setuprns("X5",tpost,tstreet,bno,"",flat)
 q matched
 
 ;
match15(tpost,tstreet,tbno,tbuild,tflat)          ;
 ;Suffix drop in number
 n matched
 s matched=0
 I $D(^UPRNX("X5",tpost,tstreet)) d
 .s $p(matchrec,",",2)="Se"
 .i tbno?1l.l1n.n d  Q
 ..f i=1:1:$l(tbno) q:($e(tbno,i)?1n)
 ..s tbno=$e(tbno,i,i+4)
 ..i $D(^UPRNX("X5",tpost,tstreet,tbno)) d
 ...I $d(^UPRNX("X5",tpost,tstreet,tbno,tbuild,tflat)) d
 ....s $p(matchrec,",",3)="Np"
 ....s $p(matchrec,",",4,5)="Be,Fe"
 ....s ALG=ALG_"match15"
 ....s matched=$$setuprns("X5",tpost,tstreet,tbno,tbuild,tflat)
 .I tbno?4n d
 ..s xtbno=$e(tbno,1,2)_"-"_$e(tbno,3,4)
 ..I $D(^UPRNX("X5",tpost,tstreet,xtbno,tbuild,tflat)) d
 ...s $p(matchrec,",",3)="Np"
 ...s $p(matchrec,",",4,5)="Be,Fe"
 ...s ALG=ALG_"match15a"
 ...s matched=$$setuprns("X5",tpost,tstreet,xtbno,tbuild,tflat)
 q matched
 ;
match14(tpost,tstreet,tbno,tbuild,tflat,skipbld)          ;
 ; Alternative post codes
 n sector
 s sector=$$sector(tpost)
 s post=""
 for  s post=$O(^UPRNX("X3",tstreet,tbno,post)) q:post=""  d  q:$G(^TUPRN($J,"MATCHED"))
 .q:post=tpost
 .i $$sector(post)'=sector q
 .S matchrec="Pi,Se,Ne"
 .s build=""
 .for  s build=$O(^UPRNX("X5",post,tstreet,tbno,build)) q:build=""  d  q:$G(^TUPRN($J,"MATCHED"))
 ..i $D(^UPRNX("X5",post,tstreet,tbno,build,tflat)) D
 ...i build=tbuild d  q
 ....s $p(matchrec,",",4,5)="Be,Fe"
 ....s ALG=ALG_"match14"
 ....s matched=$$setuprns("X5",post,tstreet,tbno,tbuild,tflat)
 ...i $g(skipbld)'="" d
 ....s $p(matchrec,",",4,5)="Bi,Fe"
 ....s ALG=ALG_"match14b"
 ....s matched=$$setuprns("X5",post,tstreet,tbno,build,tflat)
 ...I $$MPART^UPRNU(build,tbuild,1) d
 ....S $p(matchrec,",",4,5)="Bp,Fe"
 ....s ALG=ALG_"match14a"
 ....s matched=$$setuprns("X5",post,tstreet,tbno,build,tflat)
 Q $G(^TUPRN($J,"MATCHED"))
 
 ;
match19(tpost,tstreet,tbno,tbuild,tflat) 
 ;Running our of options
 ;Assumes a rough match on the number but degrades flat and building
 
 n bno,build,street,bno,flat,matched
 s matched=0
 I '$$mno(tpost,tstreet,tbno,.bno) Q 0
 s $p(matchrec,",",3)="Ne"
 i tbuild'="",tflat'="",bno'="" d
 .I $D(^UPRNX("X5",tpost,tstreet,bno,"","")) d
 ..s $p(matchrec,",",4)=$s(tbuild="":"Be",1:"Bd")
 ..s $p(matchrec,",",5)="Fd"
ub1 ..s $p(ALG,"-",2)="match19"
ub2 ..s matched=$$setuprns("X5",tpost,tstreet,bno,"","")
 Q $G(^TUPRN($J,"MATCHED"))
 
matchall(indrec)   ;
 s matchrec="Pe,Ne,Be,Fe"
 i $D(^UPRNX("X",indrec)) d  Q $G(^TUPRN($J,"MATCHED"))
 .S ALG="1-match"
 .s matched=$$setuprns("X",indrec)
 i adplural d
 .i $D(^UPRNX("X",indprec)) d
 ..S ALG="2-match"
 ..s matched=$$setuprns("X",indprec)
 Q $D(^TUPRN($J,"MATCHED"))
 
match1(tpost,tstreet,tbno,tbuild,tflat) 
 ;Match algorithms on a post code and street
 n matches
  
 ;Full 5 field match
 i $d(^UPRNX("X5",tpost,tstreet,tbno,tbuild,tflat)) d  q $G(^TUPRN($J,"MATCHED"))
 .s matchrec=$P(matchrec,",",1,2)_",Ne,Be,Fe"
 .s ALG=ALG_"match1"
 .s matched=$$setuprns("X5",tpost,tstreet,tbno,tbuild,tflat)
 Q $D(^TUPRN($J,"MATCHED"))
 
match101(tpost,tstreet,tbno,tbuild,tflat) 
 ;Match algorithms on a post code and street number range
 n matches,i
 i tbno'["-" q 0
 i tflat="" q 0
 I '$D(^UPRNX("X5",tpost,tstreet)) q 0
 f i=$p(tbno,"-",1):1:$p(tbno,"-",2) d  q:matched
 .I $D(^UPRNX("X5",tpost,tstreet,i,tbuild,tflat)) d
 ..S ALG=ALG_"match1c"
 ..s matchrec="Pe,Se,Ns,Be,Fe"
 ..s matched=$$setuprns("X5",tpost,tstreet,i,tbuild,tflat)
 Q matched
 
match102(tpost,tstreet,tbno,tbuild,tflat)        ;
 ;Post code very close
 n post,matched,near
 ;First try street and number with null flat and building
 s matched=0
 i tbuild=""!(tflat="")!(tbno="")!(tstreet="") q 0
 s matched=0
 I $D(^UPRNX("X3",tbuild,tflat)) d
 .s post=""
 .for  s post=$O(^UPRNX("X3",tbuild,tflat,post)) q:post=""  d  q:matched
 ..i post=tpost q
 ..s near=$$nearpost(post,tpost,1)
 ..q:near=""
 ..I $D(^UPRNX("X5",post,tstreet,tbno,tbuild,tflat)) d
 ...s ALG=ALG_"match1d"
 ...s matchrec=near_",Se,Ne,Be,Fe"
 ...s matched=$$setuprns("X5",post,tstreet,tbno,tbuild,tflat)
 Q matched
 
match2(tpost,tstreet,tbno,tbuild,tflat,tloc) 
 ;Assumes a match on the number and approx on other things
 
 n bno,build,street,bno,flat,matched
 s matched=0
 d bestfit^UPRNB(tpost,tstreet,tbno,tbuild,tflat,$g(tloc))
 I $D(^TUPRN($J,"MATCHED")) Q 1
 
 i $D(^TUPRN($J,"MATCHED")) Q 1 
 ;First match post, street and number
 I '$$mno(tpost,tstreet,tbno,.bno) Q 0
 s $p(matchrec,",",3)="Ne"
 i tbuild="",tflat'="",tbno'="",tstreet'="",$D(^UPRNX("X4",tpost,tstreet,tbno,tflat)) do
 .s matches=$$match2d(tpost,tstreet,tbno,tbuild,tflat)
 i matched q 1
 
 i tflat'="",tbno'="" d bsuff^UPRNU(tbno,tflat,.combine)
 s suff=""
 for  s suff=$o(combine(suff)) q:suff=""  d  q:matched
 .I $D(^UPRNX("X5",tpost,tstreet,suff,tbuild,"")) d
 ..s matchrec="Pe,Se,Nf,Be,F>Nx"
 ..s ALG=ALG_"match2cf"
 ..s matched=$$setuprns("X5",tpost,tstreet,suff,tbuild,"")
 i matched q 1
 
 
 ;Match building and flat ?
 I $D(^UPRNX("X5",tpost,tstreet,bno,tbuild)) d
 .S matchrec="Pe,Se,Ne"
 .s $p(matchrec,",",4)="Be"
dsv35 .I tbno="" q
 .i $$mflat(tpost,tstreet,bno,tbuild,tflat,.flat,.approx) d  q
 ..s $p(matchrec,",",5)="F"_approx
 ..s ALG=ALG_"match2a"
 ..s matched=$$setuprns("X5",tpost,tstreet,bno,tbuild,flat)
 .i $D(^UPRNX("X5",tpost,tstreet,bno,tbuild,"")) d
 ..i $$fbno(bno,tflat) d
 ...s $p(matchrec,",",5)="Fe"
 ..e  d
 ...s $p(matchrec,",",5)="Fc"
 ..s ALG=ALG_"match2b"
 ..;w !,tpost," ",tstreet," ",tbno," building= ",tbuild," flat ",tflat
 ..;w !,"matched to ",bno," flat=",flat r t
dsv35e ..s matched=$$setuprns("X5",tpost,tstreet,bno,tbuild,"")
 
 I $D(^TUPRN($J,"MATCHED")) Q 1
 
 ;Discovery missing the number
 i tbno="",tbuild'="",tflat'="",tstreet'="" d
 .s num=$O(^UPRNX("X5A",tpost,tstreet,tbuild,tflat,""))
 .i num'="" d
 ..s $p(matchrec,",",2,5)="Se,Ni,Be,Fe"
 ..s ALG=ALG_"match2c"
 ..s matched=$$setuprns("X5A",tpost,tstreet,tbuild,tflat,num)
 
 ;Try building Levenstein and partial match
 
 d match2c(tpost,tstreet,bno,tbuild,tflat)
 
 i $D(^TUPRN($J,"MATCHED")) Q 1 
 
 ;Possible building in flat field
 s ALG=ALG_"match2d"
 i tbuild="",$l(tflat," ")>2 d
 .I $P(tflat," ",$l(tflat," ")-1,$l(tflat," "))?1n.n1" "1l d
 ..s tflat=$p(tflat," ",1,$l(tflat," ")-1)_$p(tflat," ",$l(tflat," "))
 .i $p(tflat," ",$l(tflat," "))?1n.n.l d
 ..d match2c(tpost,tstreet,bno,$p(tflat," ",1,$l(tflat," ")-1),$p(tflat," ",$l(tflat," ")))
 
 i $D(^TUPRN($J,"MATCHED")) Q 1 
 q 0
 
match203(tpost,tstreet,tbno,tbuild,tflat) 
 ;Sector post code, exact street, number, flat and near enough building
 i (tstreet="")!(tflat="")!(tbuild="")!(tbno="") q 0
 n post,build,matched
 s post="",matched=0
 for  s post=$O(^UPRNX("X3",tstreet,tbno,post)) q:post=""  d  q:matched
 .i post=tpost q
 .i $$sector(post)'=$$sector(tpost) q
 .s build=""
 .for  s build=$O(^UPRNX("X5",post,tstreet,tbno,build)) q:build=""  d  q:matched
 ..i '$D(^UPRNX("X5",post,tstreet,tbno,build,tflat)) q
 ..i '$$matchbld^UPRNU(build,tbuild) Q
 ..S ALG=ALG_"match203"
 ..s matchrec="Pl,Se,Ne,Be,Fe" 
 ..s matched=$$setuprns("X5",post,tstreet,tbno,build,tflat)
 q matched
 
 
match202(tpost,tstreet,tbno,tbuild,tflat) 
 ;Drop building or check for weird flat/building 
 ;Windy hill, 117 hermon hill, no flat, drop building
 ;Use original building if being used in flat field
 n bno,build,street,bno,flat,matched
m1 I '$$mno^UPRN(tpost,tstreet,tbno,.bno) Q 0
 
 
 
6 ;Ignore building
 i tbuild="" d
 .I tbno="",tflat="",tbuild="" q
 .s $p(matchrec,",",4)="Ba"
 .s build=""
 .for  s build=$O(^UPRNX("X5",tpost,tstreet,bno,build)) q:build=""  d  q:$g(^TUPRN($J,"MATCHED"))
 ..i $D(^UPRNX("X5",tpost,tstreet,bno,build,tflat)) d
 ...s $p(matchrec,",",5)="Fe"
 ...s ALG=ALG_"match2f"
 ...s matched=$$setuprns("X5",tpost,tstreet,bno,build,tflat)
 .I $d(^TUPRN($J,"MATCHED")) Q
 .s $p(matchrec,",",4)="Ba"
 .s build=""
 .for  s build=$O(^UPRNX("X5",tpost,tstreet,bno,build)) q:build=""  d  q:$G(^TUPRN($J,"MATCHED"))
 ..I $$mflat(tpost,tstreet,bno,build,tflat,.flat,.approx) d
 ...s $p(matchrec,",",5)="F"_approx
 ...s ALG=ALG_"match2fa"
 ...s matched=$$setuprns("X5",tpost,tstreet,bno,build,flat)
 
7 ;Finally building name ok but won't match
 S matched=0
 i tbuild'="",tbno'="" d
 .s build=""
 .for  s build=$O(^UPRNX("X5",tpost,tstreet,bno,build)) q:build=""  d  q:matched
 ..I $D(^UPRNX("X5",tpost,tstreet,bno,build,tflat)) d
 ...s $p(matchrec,",",4)="Bi"
 ...s $p(matchrec,",",5)="Fe"
 ...s ALG=ALG_"match2fb"
 ...s matched=$$setuprns("X5",tpost,tstreet,bno,build,tflat)
 Q $G(^TUPRN($J,"MATCHED"))
 
 
 
 
mno(tpost,tstreet,tbno,bno)      ;
 ;Matches two numbers
 N matched
 s matched=0
 I $D(^UPRNX("X5",tpost,tstreet,tbno)) s bno=tbno q 1
 S tbno=$tr(tbno,"/","-")
 i tbno["-" d
 .n no
 .f no=$p(tbno,"-",1):1:$p(tbno,"-",2) d  q:matched
 ..i $D(^UPRNX("X5",tpost,tstreet,no)) d
 ...s bno=no
 q matched
 
match3(tpost,tstreet,tbno,tbuild,tflat)          ;Try from building and flat
 ;Matches using building and flat
 n street,bno,build,flat
 I '$D(^UPRNX("X3",tbuild,tflat,tpost)) q 0
 s uprn=""
 for  s uprn=$O(^UPRNX("X3",tbuild,tflat,tpost,uprn)) q:uprn=""  d  Q:matched
 .s table=""
 .for  s table=$O(^UPRNX("X3",tbuild,tflat,tpost,uprn,table)) q:table=""  d  Q:matched
 ..s key=""
 ..for  s key=$O(^UPRNX("X3",tbuild,tflat,tpost,uprn,table,key)) q:key=""  d  q:matched
 ...D GETADR^UPRNU(uprn,table,key,.flat,.build,.bno,.depth,.street,.deploc,.loc,.town,.lpost,.org)
 ...S $p(matchrec,",",2)=""
 ...I street=tstreet d
 ....s $p(matchrec,",",2)="Se"
 ...e  d
 ....I $$equiv^UPRNU(street,tstreet) d  q
 .....s $p(matchrec,",",2)="Sl"
 ....E  d
 .....I $$MPART^UPRNU(street,tstreet,1) d
 ......s $p(matchec,",",2)="Sp"
 .....e  I $$contains^UPRNU(depth,street,tstreet) d
 ......s $p(matchrec,",",2)="Se"
 ...i $p(matchrec,",",2)="" q
 ...s $p(matchrec,",",3)="Ni"
 ...i $$mno1(tbno,bno,.approx) d
 ....s $p(matchrec,",",3)="N"_approx
 ...s ALG=ALG_"match3"
 ...s matched=$$set(uprn,table,key)
 i $D(^TUPRN($J,"MATCHED")) q $G(^TUPRN($J,"MATCHED"))
 s street=""
 for  s street=$O(^UPRNX("X5",tpost,street)) q:street=""  d  q:matched
 .I $D(^UPRNX("X5",tpost,street,tbno,tbuild,tflat)) d  q
 ..S $p(matchrec,",",2,3)="Si,Ne"
 ..s ALG=ALG_"match3a"
 ..s matched=$$setuprns("X5",tpost,street,tbno,tbuild,tflat)
 i $G(^TUPRN($J,"MATCHED")) Q $G(^TUPRN($J,"MATCHED"))
 s street=""
 for  s street=$O(^UPRNX("X5",tpost,street)) q:street=""  d  q:matched
 .s bno=""
 .for  s bno=$O(^UPRNX("X5",tpost,street,bno)) q:bno=""  d
 ..I $D(^UPRNX("X5",tpost,street,bno,tbuild,tflat)) d
 ...s $p(matchrec,",",2,3)="Si,Ni"
 ...s $p(ALG,"-",2)="match3b"
 ...s matched=$$setuprns("X5",tpost,street,bno,tbuild,tflat)
 Q $G(^TUPRN($J,"MATCHED"))
 
 
match4(tpost,tstreet,tbno,tbuild,tflat)          ;Try swapping flat and building
 ;Only swap if flat doesnt exist
 i $D(^UPRNX("X3",tbuild,tflat)) q 0
 s matches=$$match1(tpost,tstreet,tflat,tbuild,tbno)
 i matches q 1
 I tbuild?1n.n.l1" "1l.e,tbno="",tflat'=""  d
 .s matches=$$match1(tpost,tstreet,tbno,$p(tbuild," ",2,10),$p(tbuild," ",1)_" "_tflat)
 s matches=$$match1(tpost,tstreet,tflat,tbuild,tbno)
 Q $G(^TUPRN($J,"MATCHED"))
 
match5(tpost,tstreet,tbno,tbuild,tflat)          ;parse for street
 n matched
 s matched=0
 I tbno'="" q 0
 n strlen,i,build
 s strlen=$l(tstreet," ")
 i tbuild="" d
 .f i=strlen-1:-1:2 do  q:matched
 ..s street=$p(tstreet," ",i,strlen)
 ..s build=$p(tstreet," ",0,i-1)
 ..I $D(^UPRNX("X5",tpost,street,tbno,build,tflat)) d
 ...s $p(matchrec,",",3)="Ne"
 ...s $p(matchrec,",",4)="Be"
 ...s $p(matchrec,",",5)="Fe"
 ...s ALG=ALG_"match5"
 ...s matched=$$setuprns("X5",tpost,street,"",build,tbno)
 ..I $D(^TUPRN($J,"MATCHED")) s matched=1
 Q $G(^TUPRN($J,"MATCHED"))
 
match5a(tpost,tstreet,tbno,tbuild,tflat)          ;Drup building number is flat
 i tflat'=""!(tbuild'="") q 0
 n build
 s build=""
 for  s build=$O(^UPRNX("X5",tpost,tstreet,"",build)) q:build=""  d  q:$g(^TUPRN($J,"MATCHED"))
 .I $D(^UPRNX("X5",tpost,tstreet,"",build,tbno)) d
 ..s matchrec="Pe,Se,Ne,Bd,Fe"
 ..S ALG=ALG_"match5a"
 ..s matched=$$setuprns("X5",tpost,tstreet,"",build,tbno)
 Q $G(^TUPRN($J,"MATCHED"))
match24(tpost,tstreet,tbno,tbuild,tflat) 
 ;run through for  sibling numbers
 n matched,front,back
 s matched=0
 s uprn=""
 for  s uprn=$O(^UPRNX("X1",tpost,uprn)) q:uprn=""  d  q:matched
 .s table=""
 .for  s table=$O(^UPRN("U",uprn,table)) q:table=""  d  q:matched
 ..s key=""
 ..for  s key=$O(^UPRN("U",uprn,table,key)) q:key=""  d  q:matched
 ...s rec=^(key)
 ...s flat=$p(rec,"~",1),build=$p(rec,"~",2)
 ...s bno=$p(rec,"~",3),depth=$p(rec,"~",4)
 ...s street=$p(rec,"~",5),deploc=$p(rec,"~",6)
 ...i street=tstreet,build=tbuild,flat=tflat d
 ....i tbno?1n.n,bno?1n.n1l d
 .....i (bno*1)=(tbno*1) d
 ......s $p(matchrec,",",2,5)="Se,Nis,Be,Fe"
 ......s ALG=ALG_"match24"
 ......s matched=$$set(uprn,table,key)
 ....i tbno?1n.n1l,bno?1n.n d
 .....i (bno*1)=(tbno*1) d
 ......s $p(matchrec,",",2,5)="Se,Nds,Be,Fe"
 ......s ALG=ALG_"match24a"
 ......s matched=$$set(uprn,table,key)
 ...I street=tstreet,build=tbuild,$$mno2(tbno,bno,flat) d
 ....s $p(matchrec,",",2,5)="Se,Ne,Be,Fe"
 ....s ALG=ALG_"match24b"
 ....s matched=$$set(uprn,table,key)
 ....S matched=1
 Q $D(^TUPRN($J,"MATCHED"))
 
match5b(tpost,tstreet,tbno,tbuild,tflat)          ;parse for street
 n matched
 s matched=0
 i tflat'="" q 0
 I tbno="" q 0
 n strlen,i,build
 s strlen=$l(tstreet," ")
 i tbuild="" d
 .f i=strlen-1:-1:2 do  q:matched
 ..s street=$p(tstreet," ",i,strlen)
 ..s build=$p(tstreet," ",0,i-1)
 ..I '$D(^UPRNX("X3",build,tbno,tpost)) q
 ..i '$D(^UPRNX("X5",tpost,street)) q
 ..S bno=""
 ..for  s bno=$O(^UPRNX("X5",tpost,street,bno)) q:bno=""  d  Q:$D(^TUPRN($J,"MATCHED"))
 ...i $D(^UPRNX("X5",tpost,street,bno,build,tbno)) d
 ....s matchrec="Pe,Se,Ni,Be,Fe"
 ....s ALG=ALG_"match5b"
 ....s matched=$$setuprns("X5",tpost,street,bno,build,tbno)
 ..I $D(^TUPRN($J,"MATCHED")) s matched=1
 Q $G(^TUPRN($J,"MATCHED"))
match25(tpost,tstreet,tbno,tbuild,tflat) 
 ;Swap flat into number, parse flat out of building
 ;Accept wrong post code
 i $d(^UPRNX("X3",tstreet,tflat)) d
 .i $p(tbuild,"flat ",2)?1n.n.l d
 ..s tbno=tflat
 ..s tflat=$p(tbuild,"flat ",2)
 ..s tbuild=$p(tbuild," flat",1)
 ..s post=""
 ..for  s post=$O(^UPRNX("X3",tstreet,tbno,post)) q:post=""  d  Q:$G(^TUPRN($J,"MATCHED"))
 ...s $p(matchrec,",",1)=""
 ...i post=tpost d
 ....s $p(matchrec,",",1)="Pe"
 ...e  d
 ....S $p(matchrec,",",1)=$$nearpost(post,adpost)
 ...I $p(matchrec,",",1)="" q
 ...i $$match1(post,tstreet,tbno,tbuild,tflat) q
 q $G(^TUPRN($J,"MATCHED"))
 
 
match45(tpost,tstreet,tbno,tbuild,tflat) 
 ;Lonshot match for this post code, ignore number
 ;or ignore ABP street if building name is long and matches
 ;dependent street match
 n matched,front,back
 k flatlist
 s matched=0
 s matchrec="Pe"
 s uprn=""
 for  s uprn=$O(^UPRNX("X1",tpost,uprn)) q:uprn=""  d  q:matched
 .s table=""
 .for  s table=$O(^UPRN("U",uprn,table)) q:table=""  d  q:matched
 ..s key=""
 ..for  s key=$O(^UPRN("U",uprn,table,key)) q:key=""  d  q:matched
 ...s rec=^(key)
 ...s flat=$p(rec,"~",1),build=$p(rec,"~",2)
 ...s bno=$p(rec,"~",3),depth=$p(rec,"~",4)
 ...s street=$p(rec,"~",5),deploc=$p(rec,"~",6)
 ...S loc=$p(rec,"~",7),town=$p(rec,"~",8)
 ...;i build["crystal" b
 ...I $l(tstreet," ")>3,tbuild="" d match45b  Q:matched
 ...i tflat=flat,tbuild'="",build="",street'="",$tr(tbuild," ")=$tr(street," ") d match45z q
 ...I tflat="",bno="",tbno=flat,build'="" d match45y q:matched
 ...i tbno=bno,$$equiv^UPRNU(depth,tstreet) d match45a q:matched
 ...i tbno="",bno'="",tflat=flat D
 ....s $p(matchrec,",",3)="Ni"
 ....s $p(matchrec,",",5)="Fe"
 ....I $$equiv^UPRNU(street,tstreet,5,2) d
 .....I $$equiv^UPRNU(build,tbuild,5,3) d
 ......s $p(matchrec,",",2)="Sl"
 ......s $p(matchrec,",",4)="Bp"
 ......S ALG=ALG_"match45"
 ......s matched=$$set(uprn,table,key)
 ...i street="",build'="",tbno=flat,tstreet=build,tbuild="",flat="" d
 ....s matchrec="Pe,Si,Ni,Be,Fe"
 ....s ALG=ALG_"match45c"
 ....s matched=$$set(uprn,table,key)
 ...i street="",build'="",bno'="",tbno=flat,tstreet=build,tbuild="",tflat="" d
 ....s matchrec="Pe,Si,Ni,Be,Fe"
 ....S ALG=ALG_"match45b"
 ....s matched=$$set(uprn,table,key)
 ...I street'="",tbno=bno,tflat=flat d
 ....i $l(tbuild," ")>2,tbuild=build d
 .....s matchrec="Pe,Si,Ne,Be,Fe"
 .....S ALG=ALG_"match45c"
 .....s matched=$$set(uprn,table,key)
 Q $g(^TUPRN($J,"MATCHED"))
 
 
match45a ;equivalent dependent with street, suffix drop on flat
 i $$mflat1(tflat,.flat,.approx) d
 .s matchrec="Pe,Sl,Ne,,F"_approx
 .s $p(matchrec,",",4)=$s(tbuild=build:"Be",tbuild'=""&(build=""):"Bd",1:"Bi")
 .s ALG=ALG_"match45a"
 .s matched=$$set(uprn,table,key)
 q
 
match45y ;Long shot on building
 I '$D(^UPRNX("X5",tpost,tstreet,"")) q
 n build
 s build=""
 for  s build=$O(^UPRNX("X5",tpost,tstreet,"",build)) q:build=""  d  q:matched
 .I '$D(^UPRNX("X5",tpost,tstreet,"",build,tbno)) q
 .i $$approx^UPRNU(build,tbuild) d
 ..s matchrec="Pe,Se,Ne,Bp,Fe"
 ..s ALG=ALG_"match45y"
 ..s matched=$$setuprns("X5",tpost,tstreet,"",build,tbno)
 q
 
match45z          ;
 s matchrec="Pe,Sd,Ne,Be,Fe"
 s ALG=ALG_"match45ab"
 s matched=$$set(uprn,table,key)
 q
 
match45b ;street contains building and street number is flat
 i flat'=tbno,bno'=tbno,tflat'=flat q
 i $$getback^UPRNU(tstreet,build_" "_street,.back) do
 .s matchrec="Pe,Sp,Ne,Bp,Fe"
 .s ALG=ALG_"match45b"
 .s matched=$$set(uprn,table,key)
 q
 
match46(tpost,tstreet,tbno,tbuild,tflat) ;
 ;Long shot partial on flat, full on building and street wrong post
 ;code, wrong number
 i tflat=""!(tbno="") q 0
 n matched
 s matched=0
 I '$D(^UPRNX("X3",tbuild)) q 0
 i '$D(^UPRNX("X3",tbuild,tflat*1)) q 0
 s post=""
 for  s post=$O(^UPRNX("X3",tbuild,tflat*1,post)) q:post=""  D  Q:$D(^TUPRN($J,"MATCHED"))
 .s $p(matchrec,",")=$$nearpost(post,tpost)
 .i $p(matchrec,",")="" q
 .s bno=""
 .for  s bno=$O(^UPRNX("X5",post,tstreet,bno)) q:bno=""  d  q:$d(^TUPRN($J,"MATCHED"))
 ..i '$D(^UPRNX("X5",post,tstreet,bno,tbuild,tflat*1)) q
 ..s $p(matchrec,",",2,5)="Se,Ni,Be,Fc"
 ..s ALG=ALG_"match46"
 ..s matched=$$setuprns("X5",post,tstreet,bno,tbuild,tflat*1)
 .I $G(^TUPRN($J,"MATCHED")) Q
 .s uprn=""
 .for  s uprn=$O(^UPRNX("X3",tbuild,tflat*1,post,uprn)) q:uprn=""  d  q:matched
 ..s table=""
 ..for  s table=$O(^UPRNX("X3",tbuild,tflat*1,post,uprn,table)) q:table=""  d  q:matched
 ...s key=""
 ...for  s key=$O(^UPRNX("X3",tbuild,tflat*1,post,uprn,table,key)) q:key=""  d  q:matched
 ....s rec=^UPRN("U",uprn,table,key)
 ....s flat=$p(rec,"~",1),build=$p(rec,"~",2)
 ....s bno=$p(rec,"~",3),depth=$p(rec,"~",4)
 ....s street=$p(rec,"~",5),deploc=$p(rec,"~",6)
 ....S loc=$p(rec,"~",7),town=$p(rec,"~",8)
 ....i $$MPART^UPRNU(tstreet,street,1) d
 .....s $p(matchrec,",",2,5)="Sp,,Be,Fe"
 .....s $p(matchrec,",",3)=$s(bno=tbno:"Ne",1:"Ns")
 .....s ALG=ALG_"match46a"
 .....s matched=$$set(uprn,table,key)
 Q $G(^TUPRN($J,"MATCHED"))
 
 
match47(tpost,tstreet,tbno,tbuild,tflat) ;
 n matched
 s matched=0
 i tbno=""!(tflat="")!(tbuild'="") q 0
 s post=""
 for  s post=$O(^UPRNX("X3",tstreet,tbno,post)) q:post=""  d  q:matched
 .i post=tpost q
 .s $p(matchrec,",")=$$nearpost(post,tpost)
 .i $p(matchrec,",")="" q
 .I '$D(^UPRNX("X5",post,tstreet,tbno,"","")) q
 .s $p(matchrec,",",2,5)="Se,Ne,Be,Fc"
 .s ALG=ALG_"match47"
 .s matched=$$setuprns("X5",post,tstreet,tbno,"","")
 q $g(^TUPRN($J,"MATCHED"))
 
match48(tpost,tstreet,tbno,tbuild,tflat) ;
 ;Try post code flat match first
 
 I tbuild="" q 0
 n flat,nbuild,xflat
 s $p(matchrec,",")="Pe"
 s xflat=tflat
 s build=""
 for  s build=$O(^UPRNX("X5",tpost,tstreet,tbno,build)) q:build=""  d  q:$D(^TUPRN($J,"MATCHED"))
 .i tbuild'[build q
 .i tflat="" s tflat=$p(tbuild," "_build)
 .s flat=""
 .for  s flat=$O(^UPRNX("X5",tpost,tstreet,tbno,build,flat)) q:flat=""  d  q:$g(^TUPRN($J,"MATCHED"))
 ..i $$mflat4(flat,tflat) d match48a(tpost,tstreet,tbno,build,flat)
 .S tflat=xflat
 i $d(^TUPRN($J,"MATCHED")) Q 1
 n post
 s post=""
 for  s post=$O(^UPRNX("X3",tstreet,tbno,post)) q:post=""  d  q:$G(^TUPRN($J,"MATCHED"))
 .I post=tpost q
 .s $p(matchrec,",")=$$nearpost(post,tpost)
 .i $p(matched,",")="" q
 .s build=""
 .for  s build=$O(^UPRNX("X5",post,tstreet,tbno,build)) q:build=""  d  q:$D(^TUPRN($J,"MATCHED"))
 ..i tbuild'[build q
 ..i tflat="" s tflat=$p(tbuild," "_build)
 ..s flat=""
 ..for  s flat=$O(^UPRNX("X5",post,tstreet,tbno,build,flat)) q:flat=""  d  Q:$g(^TUPRN($J,"MATCHED"))
 ...i $$mflat4(flat,tflat) d match48a(post,tstreet,tbno,build,flat)
 ..s tflat=xflat
 Q $G(^TUPRN($J,"MATCHED"))
 
match48a(post,street,bno,build,flat) ;
 s $p(matchrec,",",2,5)="Se,Ne,Be,Fe"
 S ALG=ALG_"match48"
 s matched=$$setuprns("X5",post,street,bno,build,flat)
 q
 ;
        
match49(tpost,tstreet,tbno,tbuild,tflat) ;
 ;Flat contains number, building is part of flat equivalent
 n suffix
 i tbno'="" q 0
 i tflat'?1n.n1l q 0
 s suffix=$e(tflat,$e(tflat))
 I '$D(^UPRNX("X5",tpost,tstreet,tflat*1,"")) q 0
 i $D(^UPRNX("X5",tpost,tstreet,tflat*1,"",tbuild)) d  q 1
 .s matchrec="Pe,Se,Ne,Be,Fe"
 .S ALG=ALG_"match49"
 .s matched=$$setuprns("X5",tpost,tstreet,tflat*1,"",tbuild)
 ;
 s flat=""
 for  s flat=$o(^UPRNX("X5",tpost,tstreet,tflat*1,"",flat)) q:flat=""  d  q:$d(^TUPRN($J,"MATCHED"))
 .i $p(flat," ")=$p(tbuild," ") d
 ..i $D(^UPRNS("FLOOR",$p(flat," "),suffix)) d
 ...s matchrec="Pe,Se,Ne,Be,Fe"
 ...s ALG=ALG_"match49a"
 ...s matched=$$setuprns(tpost,tstreet,tflat*1,"",flat)
 q $G(^TUPRN($J,"MATCHED"))
 
 
 
match51(tpost,tstreet,tbno,tbuild,tflat) ;2 field match
 n post
 n sector
 s sector=$$sector(tpost)
 s post=""
 for  s post=$O(^UPRNX("X3",tstreet,tbno,post)) q:post=""  d
 .i post=tpost q
 .i $$sector(post)'=sector q
 .i $D(^UPRNX("X5",post,tstreet,tbno,"",$tr(tflat," "))) d
 ..s matchrec="Pp,Se,Ne,Bd,Fe"
 ..s ALG=ALG_"match51"
 ..s matched=$$setuprns("X5",post,tstreet,tbno,"",$tr(tflat," "))
 q 0
 
match52(tpost,tstreet,tbno,tbuild,tflat) ;2 field match
 I tbuild'=""!(tbno'="") q 0
 I tflat=""!(tstreet="") q 0
 I '$D(^UPRNX("X3",tstreet,tflat,tpost)) q 0
 n street,bno
 d match52a(tpost,"",tbno,tstreet,tflat) i $D(^TUPRN($J,"MATCHED")) Q 1
 s street=""
 for  s street=$O(^UPRNX("X5",tpost,street)) q:street=""  d  Q:$D(^TUPRN($J,"MATCHED"))
 .d match52a(tpost,street,"",tstreet,tflat) I $D(^TUPRN($J,"MATCHED")) Q
 .s bno=""
 .for  s bno=$O(^UPRNX("X5",tpost,street,bno)) q:bno=""  d  q:$D(^TUPRN($J,"MATCHED"))
 ..d match52a(tpost,street,bno,tstreet,tflat)
 q $G(^TUPRN($J,"MATCHED"))
 
match52a(post,street,bno,build,flat)   ;
 I '$D(^UPRNX("X5",post,street,bno,build,flat)) q
 s matchrec="Pe,Si,Ni,Be,Fe"
 s ALG=ALG_"match52"
 s matched=$$setuprns("X5",post,street,bno,build,flat)
 q
 ;
match53(tpost,tstreet,tbno,tbuild,tflat) ;2 field match
 i tbuild'=""!(tflat'="") q 0
 i '$D(^UPRNX("X5",tpost,tstreet)) q 0
 n bno
 s bno=""
 for  s bno=$O(^UPRNX("X5",tpost,tstreet,bno)) q:bno=""  d  q:$D(^TUPRN($J,"MATCHED"))
 .i $D(^UPRNX("X5",tpost,tstreet,bno,"",tbno)) d
 ..s ALG=ALG_"match53"
 ..s matchrec="Pe,Se,Ne,Be,Fe"
 ..s matched=$$setuprns("X5",tpost,tstreet,bno,"",tbno)
 q $D(^TUPRN($J,"MATCHED"))
 
match54(tpost,tstreet,tbno,tbuild,tflat,tloc) ;2 field match 2 field partial
 i tbuild="",tflat="",tloc'="",tbno'="" d
 .s xbuild=tstreet
 .i $l(xbuild," ")<2 q
 .s flat=tbno
 .s xstreet=tloc
 .s bno=""
 .s build=xbuild
 .i $l(xstreet," ")<2 q
 .for  s build=$O(^UPRNX("X3",build)) q:($p(build," ",1,$l(xbuild," "))'=xbuild)  d
 ..i '$D(^UPRNX("X3",build,flat,tpost)) q
 ..f i=2:1:$l(xstreet," ") d  q:$D(^TUPRN($J,"MATCHED"))
 ...s street=$p(xstreet," ",1,i)
 ...for  s street=$o(^UPRNX("X5",tpost,street)) q:($p(street," ",1,i)'=$p(xstreet," ",1,i))  d
 ....i '$d(^UPRNX("X5",tpost,street,"",build,flat)) q
 ....s ALG=ALG_"match54"
 ....s matchrec="Pe,Sp,Ne,Bp,Fe"
 ....s matched=$$setuprns("X5",tpost,street,"",build,flat)
 Q $G(^TUPRN($J,"MATCHED"))
 
match55(tpost,tstreet,tbno,tbuild,tflat,tloc) ;2 field match 
 I tbuild=""!(tflat="")!(tbno="")!(tstreet="") q 0
 I '$D(^UPRNX("X3",tstreet,tflat_" "_tbuild_" "_tbno,tpost)) q 0
 s ALG=ALG_"match55"
 s matchrec="Pe,Si,Ne,Be,Fe"
 s matched=$$setuprns("X3",tstreet,tflat_" "_tbuild_" "_tbno,tpost)
 Q $D(^TUPRN($J,"MATCHED"))
match56(tpost,tstreet,tbno,tbuild,tflat,tloc) ;2 field match 
 I tbuild'=""!(tflat'="") D
 .i tstreet'="",tbno'="" d
 ..I $D(^UPRNX("X5",tpost,tstreet,tbno*1,"","")) d
 ...s matchrec="Pe,Se,Na,Bd,Fd"
 ...S ALG=ALG_"match56"
 ...s matched=$$setuprns("X5",tpost,tstreet,tbno*1,"","")
 Q $D(^TUPRN($J,"MATCHED"))
 
match57(tpost,tstreet,tbno,tbuild,tflat,tloc) ;2 field match 
 i tbuild'="",tstreet'="" d
 .I '$D(^UPRNX("X5",tpost,tbuild_" "_tstreet)) q
 .I tbno="",tflat'="" d
 ..I '$D(^UPRNX("X5",tpost,tbuild_" "_tstreet,tflat*1,"")) q
 ..s matchrec="Pe,Se,Na,Be,Fe"
 ..s ALG=ALG_"match57"
 ..s matched=$$setuprns("X5",tpost,tbuild_" "_tstreet,tflat*1,"","")
 Q $D(^TUPRN($J,"MATCHED"))
 
match58(tpost,tstreet,tbno,tbuild,tflat,tloc) ;2 field match 
 i '$D(^UPRNX("X5",tpost)) q 0
 i $l(tstreet," ")<2 q 0
 s xstreet=$O(^UPRNX("X5",tpost,$p(tstreet," ")))
 i xstreet'[$p(tstreet," ") q 0
 i $l(xstreet," ")'=3 q 0
 i '$d(^UPRNX("X5",tpost,xstreet,tbno)) q 0
 I $D(^UPRNX("X5",tpost,xstreet,tbno,tbuild,tflat)) d  q 1
 .s matchrec="Pe,Sp,Ne,Be,Fe"
 .S ALG=ALG_"match58"
 .s matched=$$setuprns("X5",tpost,xstreet,tbno,tbuild,tflat)
 I $D(^UPRNX("X5",tpost,xstreet,tbno,tbuild,"")) d
 .s matchrec="Pe,Sp,Ne,Be,Fc"
 .S ALG=ALG_"match58"
 .s matched=$$setuprns("X5",tpost,xstreet,tbno,tbuild,"")
 Q $D(^TUPRN($J,"MATCHED"))
match59(tpost,tstreet,tbno,tbuild,tflat) 
 ;Lonshot match for this post code, street is building ignore ABP street
 s matched=0
 s matchrec="Pe"
 s uprn=""
 for  s uprn=$O(^UPRNX("X1",tpost,uprn)) q:uprn=""  d  q:matched
 .s table=""
 .for  s table=$O(^UPRN("U",uprn,table)) q:table=""  d  q:matched
 ..s key=""
 ..for  s key=$O(^UPRN("U",uprn,table,key)) q:key=""  d  q:matched
 ...s rec=^(key)
 ...s flat=$p(rec,"~",1),build=$p(rec,"~",2)
 ...s bno=$p(rec,"~",3),depth=$p(rec,"~",4)
 ...s street=$p(rec,"~",5),deploc=$p(rec,"~",6)
 ...S loc=$p(rec,"~",7),town=$p(rec,"~",8)
 ...I street'="",tbno=bno,tflat=flat d
 ....i $l(tstreet," ")>2,tstreet=build d
 .....s matchrec="Pe,Si,Ne,Be,Fe"
 .....S ALG=ALG_"match59"
 .....s matched=$$set(uprn,table,key)
 Q $g(^TUPRN($J,"MATCHED"))
 
match27(tpost,tstreet,tbno,tbuild,tflat) 
 i tstreet="" q 0
 i $$isroad^UPRNA(tstreet),$$isroad^UPRNA(tbuild) d
 .I '$D(^UPRNX("X5",tpost,tbuild,tflat)) q
 .I $d(^UPRNX("X5",tpost,tbuild,tflat,"","")) d
 ..s ALG=ALG_"match27"
 ..s $p(matchrec,",",2,5)="Se,Ne,Bd,Fd"
 ..s matched=$$setuprns("X5",tpost,tbuild,tflat,"","")
 Q $G(^TUPRN($J,"MATCHED"))
 
 
match28(tpost,tstreet,tbno,tbuild,tflat) 
 ;Strips out flat and building
 s tflat=tbno,tbno=""
 n i,t1,t2
 f i=1:1:$l(tstreet," ") d  q:$G(^TUPRN($J,"MATCHED"))
 .s t1=$p(tstreet," ",1,i)
 .I $D(^UPRNX("X3",t1,tflat)) d
 ..s t2=$p(tstreet," ",i+1,20)
 ..s matches=$$match7(tpost,t2,"",t1,tflat)
 q $G(^TUPRN($J,"MATCHED"))
 
match60(tpost,tstreet,tbno,tbuild,tflat,tloc) 
 ;Right shifts into locality
 i adbno'=""!(tloc'="") q 0
 I $D(^UPRNX("X5",tpost,tbuild,tflat,"","")) d
 .i '$$isroad^UPRNA(tstreet) d
 ..s matchrec="Pe,Se,Ne,Be,Fe"
 ..S ALG=ALG_"match60"
 ..s matched=$$setuprns("X5",tpost,tbuild,tflat,"","")
 Q $G(^TUPRN($J,"MATCHED"))
 
match62(tpost,tstreet,tbno,tbuild,tflat,tloc,tdeploc) 
 s post=""
 for  s post=$O(^UPRNX("X3",tstreet,tbno,post)) q:post=""  d  q:$d(^TUPRN($J,"MATCHED"))
 .q:post=tpost
 .s near=$$justarea(post,qpost)
 .q:near=""
 .s $p(matchrec,",",1)=near
 .i $D(^UPRNX("X5",post,tstreet,tbno,tbuild,tflat)) d
 ..s $p(matchrec,",",2,5)="Se,Ne,Be,Fe"
 ..S ALG=ALG_"match62"
 ..s matched=$$setuprns("X5",post,tstreet,tbno,tbuild,tflat)
 Q $G(^TUPRN($J,"MATCHED"))
justarea(post,adpost) 
 i $$area(adpost)=adpost,$$area(post)=adpost q "Pp"
 Q ""
 
match61(tpost,tstreet,tbno,tbuild,tflat,tloc,tdeploc) 
 ;post code, street and number, street has 'es'
 s matched=0
 s matchrec="Pe"
 s uprn=""
 for  s uprn=$O(^UPRNX("X1",tpost,uprn)) q:uprn=""  d  q:matched
 .s table=""
 .for  s table=$O(^UPRN("U",uprn,table)) q:table=""  d  q:matched
 ..s key=""
 ..for  s key=$O(^UPRN("U",uprn,table,key)) q:key=""  d  q:matched
 ...s rec=^(key)
 ...s flat=$p(rec,"~",1),build=$p(rec,"~",2)
 ...s bno=$p(rec,"~",3),depth=$p(rec,"~",4)
 ...s street=$p(rec,"~",5),deploc=$p(rec,"~",6)
 ...S loc=$p(rec,"~",7),town=$p(rec,"~",8)
 ...I tflat="",flat="",bno="",tbno="",tstreet'="",street="" d  q
 ....i $$equiv^UPRNU(tstreet,build,8,1) d
 .....s matchrec="Pe,S>B,Ne,Bf,Fe"
 .....s ALG=ALG_"match61f"
 .....s matched=$$set(uprn,table,key)
 ...I tflat="",tbuild="",street="",bno="",flat="",build'="" d
 ....d flatbld^UPRNA(.flat,.build)
 ....i tbno=flat,$$equiv^UPRNU(tstreet,build,8) d
 .....i tdeploc=loc d
 ......s matchrec="Pe,Sl>B,N>B,Bf,Ff"
 ......s ALG=ALG_"match61e"
 ......s matched=$$set(uprn,table,key)
 ...i tflat="",tbuild="",bno="",tbno'="" d  q:$G(^TUPRN($J,"MATCHED"))
 ....I flat=tbno,$$equiv^UPRNU(build,tstreet,6,1) d
 .....i loc=tloc D
 ......S matchrec="Pe,Sl>B,N>F,Bl,Fe"
 ......S ALG=ALG_"match61d"
 ......s matched=$$set(uprn,table,key)
 ...i $$equiv^UPRNU(street,tstreet) d  q
 ....i bno=""!(tbno="") q
 ....i bno'=tbno q
 ....i tflat'=flat!(tbuild'=build) q
 ....s matchrec="Pe,Se,Ne,Be,Fe"
 ....S ALG=ALG_"match61"
 ....s matched=$$set(uprn,table,key)
 ...i $$equiv^UPRNU($e($tr(tstreet," "),1,8),street,8,1) d
 ....i bno'="",tbno=bno,build=tbuild,flat=tflat d
 .....s matchrec="Pe,Sp,Ne,Be,Fe"
 .....S ALG=ALG_"match61g"
 .....s matched=$$set(uprn,table,key)
 Q $g(^TUPRN($J,"MATCHED"))
 
setuprns(index,n1,n2,n3,n4,n5) 
 n uprn,table,key
 s matched=0
 s (uprn,table,key)=""
 i index="X" d
 .for  s uprn=$O(^UPRNX(index,n1,uprn)) q:uprn=""  d
 ..for  s table=$O(^UPRNX(index,n1,uprn,table)) q:table=""  d
 ...for  s key=$O(^UPRNX(index,n1,uprn,table,key)) q:key=""  d
 ....s matched=$$set(uprn,table,key)
 
 i index["X5"!(index["X2")!(index["X4") d
 .for  s uprn=$O(^UPRNX(index,n1,n2,n3,n4,n5,uprn)) q:uprn=""  d
 ..for  s table=$O(^UPRNX(index,n1,n2,n3,n4,n5,uprn,table)) q:table=""  d
 ...for  s key=$O(^UPRNX(index,n1,n2,n3,n4,n5,uprn,table,key)) q:key=""  d
 ....s matched=$$set(uprn,table,key)
 i index="X3"!(index="X3") d
 .for  s uprn=$O(^UPRNX(index,n1,n2,n3,uprn)) q:uprn=""  d
 ..for  s table=$O(^UPRNX(index,n1,n2,n3,uprn,table)) q:table=""  d
 ...for  s key=$O(^UPRNX(index,n1,n2,n3,uprn,table,key)) q:key=""  d
 ....s matched=$$set(uprn,table,key)
 q matched
set(uprn,table,key) ;
 i '$$isok^UPRNU(uprn) q 0
 i '$D(^TUPRN($J,"MATCHED",uprn)) d
 .S ^TUPRN($J,"MATCHED")=$g(^TUPRN($J,"MATCHED"))+1
 s ^TUPRN($J,"MATCHED",uprn,table,key)=matchrec
 S ^TUPRN($J,"MATCHED",uprn,table,key,"A")=ALG
 q 1
 
 
 
nearest(test,before,after)    ;Returns the nearest number
 N nearest
 s nearest(test)=""
 i before'="" d
 .s nearest(before)=""
 i after'="" d
 .s nearest(after)=""
 i $o(nearest(test))="" q before
 i $o(nearest(test),-1)="" q after
 i after-test<(test-before) q after
 q before
 
 
 
mflat(tpost,tstreet,tbno,tbuild,tflat,flat,approx)         ;
 N matched,flats
 s matched=0
 
 ;null flat match
 i tflat="",$D(^UPRNX("X5",tpost,tstreet,tbno,tbuild,"")) d
 .s approx="e"
 .s matched=1
 .s flat=""
 i matched q 1
 
 ;Fuzzy flat match
 i tflat?1n.n1" "1l.e d
 .I $D(^UPRNX("X5",tpost,tstreet,tbno,tbuild,tflat*1)) d
 ..s flat=tflat*1
 ..s approx="p"
 ..s matched=1
 i matched q matched
 
 i tflat?1l.l.e d
 .s flat=$O(^UPRNX("X5",tpost,tstreet,tbno,tbuild,$p(tflat," ")))
 .i flat[tflat d  q
 ..s approx="p"
 ..s matched=1
 .d swap^UPRNU(.tflat)
 .s flat=$O(^UPRNX("X5",tpost,tstreet,tbno,tbuild,$p(tflat," ")))
 .i flat[$P(tflat," ") d
 ..S approx="p"
 ..s matched=1
 
 i matched q 1
 ;
 ;Cycles through flats
 s flat=""
 for  s flat=$O(^UPRNX("X5",tpost,tstreet,tbno,tbuild,flat)) q:flat=""  d  q:matched
 .s flats(flat)=""
 i $d(^UPRNS("VERTICALS",tflat)) d
 .f i="b",2,"a",1 d  q:matched
 ..;i $d(flats(flat,i)) s matched=1,approx="s"
 ..i $d(flats(i)) s matched=1,approx="s"
 i matched q 1
 
 s flat=""
 for  s flat=$O(^UPRNX("X5",tpost,tstreet,tbno,tbuild,flat)) q:flat=""  d  q:matched
 .i $$mflat1(tflat,flat,.approx) D  q
 ..s matched=1
 i matched q matched
 
 ;o228 should be 228 o
 I tflat?1l1n.n d
 .n xflat
 .s xflat=$e(tflat,2,20)_" "_$e(tflat)
 .I $D(^UPRNX("X5",tpost,tstreet,tbno,tbuild,xflat)) d  q
 ..s approx="e"
 ..s matched=1
 ..s flat=xflat
 .s zflat=$O(^UPRNX("X5",tpost,tstreet,tbno,tbuild,xflat),-1)
 .i zflat?1n.n1" "1l d
 ..s approx="s"
 ..s matched=1
 ..s flat=zflat
 i matched q 1
 
 i tflat?1n.n d
 .s near1=$O(^UPRNX("X5",tpost,tstreet,tbno,tbuild,tflat),-1)
 .s near2=$O(^UPRNX("X5",tpost,tstreet,tbno,tbuild,tflat))
 .s near=$$nearest(tflat,near1,near2)
 .i near'="" d  q
 ..S flat=near
 ..s matched=1
 ..s approx="s"
 .i near="" d  q
 ..s matched=1
 ..s flat=""
 ..s approx="c"
 
 ;Must be a parent approximation
 I 'matched,tflat="" d
 .s approx="a"
 .s matched=1
 .S flat=$O(^UPRNX("X5",tpost,tstreet,tbno,tbuild,""))
 q matched
 
mflat1(tflat,flat,approx) ;Matches two flats
 n matched,tflatno
 s matched=0
 
 ;5-6
 i flat["-" d
 .i tflat=$p(flat,"-")!(tflat=$p(flat,"-",2)) d
 ..s matched=1
 ..s approx="e"
 .I tflat*1=$p(flat,"-",2)!(tflat*1=$p(flat,"-",1)) d  Q
 ..s matched=1
 ..s approx="ds"
 .i tflat>$p(flat,"-")&(tflat<$p(flat,"-",2)) d
 ..s matched=1
 ..s approx="e"
 i matched q 1
 
 i tflat["-" d
 .i flat=$p(tflat,"-")!(flat=$p(tflat,"-",2)) d
 ..s matched=1
 ..s approx="s"
 
 i matched q 1
 
 ;workshop 6
 i $p(tflat," ",$l(tflat," "))?1n.n.l d
 .set tflatno=$p(tflat," ",$l(tflat," "))
 .if tflatno=flat d
 ..s approx="e"
 ..s matched=1
 i matched q 1
 
 ;flat 6 f
 s tflat=$tr(tflat," "),flat=$tr(flat," ")
 
 ;3c to 4
 i tflat?1n.n.1l,flat?1n.n,(flat*1=(tflat*1)) d
 .s matched=1
 .s approx="ds"
 i tflat?1n.n,(flat*1)=tflat*1 d
 .s matched=1
 .s approx="is"
 
        
 
 q matched
mflat4(flat,tflat) ;Weird flat match
 n matched,num,suffix,i
 s matched=0
 I flat?1l1" ".e d 
 .s suffix=$p(flat," ")
 .s num=$p(flat," ",$l(flat," "))
 .i num?1n.n d
 ..i (" "_tflat_" ")[(" "_num_suffix_" ")!(" "_tflat_" "[(" "_suffix_num_" ")) d
 ...s matched=1
 ..i $e(tflat,1,$l(suffix_num))=(suffix_num),$p(tflat,suffix_num,2)?1l d
 ...s matched=1
 ..i (tflat*1)=num,$e(tflat,$l(tflat))=suffix d
 ...s matched=1
 q matched
mflat3(tflat,flatlist,flat)  ;
 n offset
 i tflat'?1n.n q
 i $o(flatlist("base"))["base" s offset=1
 s tflat=tflat-offset
 i tflat=0,$o(flatlist("ground"))["ground" d  q 1
 .s flat=$o(flatlist("ground"))
 i tflat=1,$o(flatlist("first"))["first" d  q 1
 .s flat=$o(flatlist("first"))
 i tflat=2,$o(flatlist("second"))["second" d  q 1
 .s flat=$o(flatlist("second"))
 i tflat=3,$o(flatlist("third"))["third" d  q 1
 .s flat=$o(flatlist("third"))
 q 0
mflat2(flat,tflat) ;Matches 2 flats fuzzy match
 n matched
 s matched=0
 i flat=""!(tflat="") q 0
 s flat=$$flat^UPRNU(flat)
 i tflat?1n.n!(tflat?1n.n1l) d
 .i flat[tflat s matched=1
 q matched
 
mno1(tbno,bno,approx) ;Matches two numbers
 n matched
 s matched=0
 s approx="e"
 i tbno=bno q 1
 ;94a to 94
 i tbno?1n.n1l,bno?1n.n,(bno*1=(tbno*1)) d
 .s matched=1
 .s approx="ds"
 i tbno?1n.n,(bno*1)=tbno*1 d
 .s matched=1
 .s approx="is"
 i tbno?1n.n1"-"1n.n d
 .i bno?1n.n1"-"1n.n d  q
 ..i $p(tbno,"-")'<$p(bno,"-") d
 ...i $p(tbno,"-",2)'>$p(bno,"-",2) d
 ....s matched=1
 .i bno'<$p(tbno,"-"),bno'>$p(tbno,"-",2) d
 ..s matched=1
 i bno?1n.n1"-"1n.n d
 .i tbno?1n.n1"-"1n.n d  q
 ..i $p(bno,"-")'<$p(tbno,"-") d
 ...i $p(bno,"-",2)'>$p(tbno,"-",2) d
 ....s matched=1
 .i tbno'<$p(bno,"-"),tbno'>$p(bno,"-",2) d
 ..s matched=1
 
 q matched
mno2(tbno,bno,flat)          ;Looks for range splits
 N matched
 s matched=0
 i tbno?1n.n.l,bno["-" d
 .i tbno*1'<$p(bno,"-"),tbno*1'>($p(bno,"-",2)) d
 ..i tbno?1n.n1l i $p(tbno,tbno*1,2)=$g(flat) d
 ...s matched=1
 ..e  i tbno?1n.n s matched=1
 q matched
 
nomatch ;Records no match
 s ^TUPRN($J,"NOMATCH")=""
 i $g(ui)>1 d
 .w !,address
 .zwr address
 .r t
 ;Exception
 q
 
matched ;
 I $G(^TPOSS($J))=2 K ^TUPRN($J,"MATCHED") Q
 n table,key
 I ^TUPRN($J,"MATCHED")>1 D sort
 S uprn=""
 for  s uprn=$O(^TUPRN($J,"MATCHED",uprn)) q:uprn=""  d
 .s table=""
 .for  s table=$O(^TUPRN($J,"MATCHED",uprn,table)) q:table=""  d
 ..s key=""
 ..for  s key=$O(^TUPRN($J,"MATCHED",uprn,table,key)) q:key=""  d
 ...s matchrec=^(key)
 ...s ALG=^TUPRN($J,"MATCHED",uprn,table,key,"A")
 ...I table="D",$p(matchrec,",",4)="Bd" d
 ....I adbuild'="" d
 .....i $P(^UPRN("U",uprn,table,key),"~",10)=adbuild d
 ......s $p(matchrec,",",4)="Be"
 ......s ^TUPRN($J,"MATCHED",uprn,table,key)=matchrec
 ......s ^TUPRN($J,"MATCHED",uprn,table,key,"A")=ALG
 q
SETBATCH(matched) ;Sets the batch matched update
 s uprn=""
 for  s uprn=$O(^TUPRN($J,"MATCHED",uprn)) q:uprn=""  d
 .s table=""
 .for  s table=$O(^TUPRN($J,"MATCHED",uprn,table)) q:table=""  d
 ..s key=""
 ..for  s key=$O(^TUPRN($J,"MATCHED",uprn,table,key)) q:key=""  d
 ...s matchrec=^(key)
 ...s ALG=^TUPRN($J,"MATCHED",uprn,table,key,"A")
 ...S ^UPRNI("M",adno,uprn,table,key)=matchrec
 ...S ^UPRNI("M",adno,uprn,table,key,"A")=ALG
 ...S ^UPRNI("Stats","ALG",ALG)=$G(^UPRNI("Stats","ALG",ALG))+1
 i matched d
 .S ^UPRNI("Stats","Matched")=$G(^UPRNI("Stats","Matched"))+1
 e  d
 .S ^UPRNI("Stats","Unmatched")=$G(^UPRNI("Stats","Unmatched"))+1
 .S ^UPRNI("UM",adno)=""
 q
 q
 
sort ;
 K ^TUPRN1($j)
 s uprn="",key=""
 for  s uprn=$O(^TUPRN($J,"MATCHED",uprn)) q:uprn=""  d
 .s order=1
 .s class=$G(^UPRN("CLASS",uprn))
 .i class'="",$e(class)'="R" s order=100
 .S status=$P(^UPRN("U",uprn),"~",3)
 .i status=8 s order=order+1
 .M ^TUPRN1($J,order,uprn)=^TUPRN($J,"MATCHED",uprn)
 k ^TUPRN($J)
 S ^TUPRN($J,"MATCHED")=1
 S order=$O(^TUPRN1($J,""))
 S uprn=$O(^TUPRN1($J,order,""))
 M ^TUPRN($J,"MATCHED",uprn)=^TUPRN1($J,order,uprn)
 Q
 Q
 Q
 
 Q
 
ONE ;
 s adno=^ADNO
 s xadno=adno
 d batch("D","",adno,adno,2)
 s adno=xadno
 Q
 ;
 ;
clrvars ;Resetset the flags
 S WRONGPOST=""
 S SUFFIGNORE=""
 S FLATNC="",SUPRA=""
 S NUMSTREET=""
 s ALG=""
 s FIELDS=""
 
 S FLAT="",PLURAL="",DROP="",CORRECT=""
 S SWAP="",DUPL="",SUB="",SIMILAR="",PARTIAL=""
 S ANDLPI="",FIRSTPART="",LEVENOK="",SIBLING="",SUPRA=""
 S SUFFDROP="",SUBFLATI="",SUBFLATD=""
 Q
inpost(post,qpost) ;
 n in,i,q,area
 s in=0
 i post="" q 1
 s area=$$area(post)
 i qpost="" d  q in
 .i $D(^UPRN("AREAS",area)) s in=1
 i ","_qpost_","[(","_area_",") s in=1
 q in
area(post)         ;
 n area,done
 s area="",done=0
 f i=1:1:$l(post) d  q:done
 .i $e(post,i)?1n s done=1 q
 .s area=area_$e(post,i)
 q area
sector(post,rest)       ;returns post code to sector level
 n i,sector
 s sector="",rest=""
 f i=$l(post):-1:0 d  q:(sector'="")
 .i $e(post,i)?1n s sector=$e(post,1,i),rest=$e(post,i+1,$l(post))
 q sector
