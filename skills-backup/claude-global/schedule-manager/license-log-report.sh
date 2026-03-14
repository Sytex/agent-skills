#!/bin/bash
# License Log Report - sytex_app
# Generates CSV of license log entries for the current month

MONTH=$(date +%Y_%m)
OUTFILE="/tmp/license_log_${MONTH}.csv"

~/.claude/skills/database/database --db prod-us --database sytex_app query "
SELECT 
    ll.id,
    ll.when_created,
    o.name AS organization,
    p.name AS product,
    ll.quantity,
    CASE ll.type 
        WHEN 1 THEN 'SIT'
        WHEN 2 THEN 'UNSIT'
        WHEN 3 THEN 'PURCHASE'
        WHEN 4 THEN 'REMOVE'
    END AS type,
    CASE ll.assigned_person_content_type_id
        WHEN 25 THEN CONCAT(COALESCE(sp.name, 'N/A'), ' (Staff)')
        WHEN 79 THEN CONCAT(COALESCE(cp.name, 'N/A'), ' (Contact)')
        ELSE NULL
    END AS assigned_person
FROM licenses_licenselog ll
JOIN organizations_organization o ON o.id = ll.organization_id
JOIN licenses_product p ON p.id = ll.product_id
LEFT JOIN people_staff s 
    ON ll.assigned_person_content_type_id = 25 AND s.id = ll.assigned_person_id
LEFT JOIN sytexauth_user su ON s.related_user_id = su.id
LEFT JOIN people_profile sp ON su.profile_id = sp.id
LEFT JOIN people_contact c 
    ON ll.assigned_person_content_type_id = 79 AND c.id = ll.assigned_person_id
LEFT JOIN sytexauth_user cu ON c.related_user_id = cu.id
LEFT JOIN people_profile cp ON cu.profile_id = cp.id
WHERE ll.is_inactive = 0
  AND ll.when_created >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
  AND ll.when_created < DATE_FORMAT(CURDATE() + INTERVAL 1 MONTH, '%Y-%m-01')
ORDER BY ll.when_created, o.name
" csv > /tmp/license_log_raw.csv 2>/dev/null

# Clean and format CSV
echo 'id,when_created,organization,product,quantity,type,assigned_person' > "$OUTFILE"
grep -v "^mysql:" /tmp/license_log_raw.csv | awk -F'\t' '{for(i=1;i<=NF;i++){if(i>1)printf ",";gsub(/"/, "\"\"", $i);printf "\"%s\"", $i}printf "\n"}' >> "$OUTFILE"

ROWS=$(($(wc -l < "$OUTFILE") - 1))
echo "FILE:${OUTFILE}"
echo "ROWS:${ROWS}"
echo "MONTH:$(date +%B\ %Y)"
