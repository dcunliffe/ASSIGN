POURC ; ; 4/11/24 3:13pm
 quit
 ;	
 ; job SERVICE^POURC:(out="/dev/null")
 ; $ydb_dist/mupip intrpt 18790 (where 18790 is $job)
SERVICE ;
 new job,i,zi,qid
 ;	
 S ^DSYSTEM("POURC")=$job
 set $ZINT="I $$JOBEXAM^POURC($ZPOS)"
 set job=+$get(^KRUNNING("START","POURC"))
 lock ^KRUNNING("START","POURC"):1
 if '$t S ^T($J)="POURC:locked" quit
 ;	
 kill ^KRUNNING("STOP","POURC")
 set ^KRUNNING("START","POURC")=$job
 for i=1:1 quit:$data(^KRUNNING("ABORT","POURC"))  do
 . w !,"hanging 10"
 . hang 10
 . set (qid,zi)=""
 . for  set qid=$order(^ZQZ(qid)) q:qid=""  do
 . . for  set zi=$order(^ZQZ(qid,zi)) q:zi=""  do
 . . . if $data(^ZQZ1(qid,zi)) quit
 . . . D RUN(qid,zi)
 . . . quit
 . . quit
 . quit
 ;	
 set ^KRUNNING("STOP","POURC")=$job
 lock -^KRUNNING("START","POURC")
 quit
 ;	
RUN(qid,zzi) ;
 new t1,rtn
 ;	
 set t1=^ZQZ(qid,zzi)
 if zzi>+$H quit
 if t1>$piece($horolog,",",2) quit
 ;	
 set rtn=$get(^ZQZ(qid,zzi,"RTN"))
 if rtn'="" do  quit
 . do @rtn
 . set ^ZQZ1(qid,zzi)=$Horolog
 . D SLACK($get(^ICONFIG("POURC","MESS",rtn),"?"))
 . quit
 ; belt and braces
 set ^ZQZ1(qid,zzi)=$Horolog
 quit
 ;	
MESS ;
 set ^ICONFIG("POURC","MESS","PROCESS^ABPAPI2")="Test ABP change only process finished ok"
 quit
 ;
 ;			
TEST ;
 set ^ZQZ(1)="ABP change only updates"
 
 set z=$P($H,",",2)+120,^ZQZ(1,+$H)=z,^ZQZ(1,+$h,"RTN")="PROCESS^ABPAPI2" K ^ZQZ1(1,+$H)
 
 ;uprn slack channel
 ;S ^ICONFIG("POURC","SLACK")="https://hooks.slack.com/services/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"
 ;endeavour slack channel
 S ^ICONFIG("POURC","SLACK")="https://hooks.slack.com/services/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"
 quit
 ;	
ZQZ ;
 new i
 ; run for the next 5 days
 kill ^ZQZ(1)
 set ^ZQZ(1)="ABP change only updates"
 f i=(+$H+1):1:(+$Horolog+5) do
 . S ^ZQZ(1,i)=$$TH^STDDATE("00:05")
 . set ^ZQZ(1,i,"RTN")="PROCESS^ABPAPI2"
 . quit
 quit
 ;	
SLACK(text) ;
 new json,cmd,webhookurl
 set webhookurl=$get(^ICONFIG("POURC","SLACK"))
 if webhookurl="" quit
 set json="{""text"":"""_text_"""}"
 set cmd="curl -i -X POST -H ""Content-Type: application/json"" "
 set cmd=cmd_"-d '"_json_"' "
 set cmd=cmd_webhookurl
 zsystem cmd
 quit
 ;	
JOBEXAM(%ZPOS) 
 s idx=$o(^interupt(""),-1)+1
 S ^interupt(idx)=$get(%ZPOS)
 D LOG
 quit
 ;	
LOG ;
 K ^LOG
 S %D=$H,%I="exam"
 S %TOP=$STACK(-1),%N=0
 F %LVL=0:1:%TOP S %N=%N+1,^LOG("log",%D,$J,%I,"error","stack",%N)=$STACK(%LVL,"PLACE")_":"_$STACK(%LVL,"MCODE")
 N %X,%Y
 S %X="^LOG(""log"",%D,$J,%I,""error"",""symbols"","
 S %Y="%" F  M:$D(@%Y) @(%X_"%Y)="_%Y) S %Y=$O(@%Y) Q:%Y=""
 quit
