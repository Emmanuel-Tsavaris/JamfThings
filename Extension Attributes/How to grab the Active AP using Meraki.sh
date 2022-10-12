#!/bin/bash

activeAP=$( curl http://ap.meraki.com/index.json 2>/dev/null | python -c 'import sys, json; \
print json.dumps( json.loads( sys.stdin.read() ), sort_keys=True, indent=4)' | \
grep node_name | awk '{print $2}' | sed -e 's/^"//g' | sed -e 's/",$//g' )

case $activeAP in

    NP-0502-CR-AP-01 | NP-0502-CR-AP-02 | NP-0502-CR-AP-03 | NP-0502-CR-AP-04 | NP-0502-CR-AP-05 | NP-0502-CR-AP-06)
        department="Cardinal"
        echo "<result>$department</result>"
        ;;

    NP-0502-DV-AP-01 | NP-0502-DV-AP-02 | NP-0502-DV-AP-03 | NP-0502-DV-AP-04 | NP-0502-DV-AP-05)
        department="Dove"
        echo "<result>$department</result>"
        ;;

    NP-0502-GYM-AP-01)
        department="Gym"
        echo "<result>$department</result>"
        ;;

    NP-0502-FC-01)
        department="Facilities"
        echo "<result>$department</result>"
        ;;

    NP-0502-GH-AP-01)
        department="Guard House"
        echo "<result>$department</result>"
        ;;
    
    NP-0502-HK-AP-01 | NP-0502-HK-AP-02 | NP-0502-HK-AP-03 | NP-0502-HK-AP-04)
        department="Hawk"
        echo "<result>$department</result>"
        ;;

    NP-0502-LO-AP-01 | NP-0502-LO-AP-02 | NP-0502-LO-AP-03 | NP-0502-LO-AP-04)
        department="Lodge"
        echo "<result>$department</result>"
        ;;

    NP-0502-P1-AP-01)
        department="Pods"
        echo "<result>$department</result>"
        ;;

    NP-0502-YURT-AP-01)
        department="Yoga"
        echo "<result>$department</result>"
        ;;

    PLOW-HQ-AP-2 | PLOW-HQ-AP-3 | PLOW-HQ-AP-4)
        department="Plow HQ"
        echo "<result>$department</result>"
        ;;

    *)
        department="Unknown"
        echo "<result>$department</result>"
        ;;
esac