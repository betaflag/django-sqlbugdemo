SELECT
    `myapp_organization`.`id`,
    `myapp_organization`.`name`,
    COUNT(`myapp_member`.`id`) AS `member__count`
FROM
    `myapp_organization`
    LEFT OUTER JOIN `myapp_member` ON (
        `myapp_organization`.`id` = `myapp_member`.`organization_id`
    )
WHERE
    EXISTS(
        SELECT
            1 AS `a`
        FROM
            `myapp_organization` U0
            LEFT OUTER JOIN `myapp_member` U1 ON (U0.`id` = U1.`organization_id`)
            LEFT OUTER JOIN `myapp_member` U2 ON (U0.`id` = U2.`organization_id`)
        WHERE
            (
                (
                    U0.`name` LIKE '%a%'
                    OR U2.`name` LIKE '%a%'
                )
                AND U0.`id` = (`myapp_organization`.`id`)
            )
        GROUP BY
            U0.`id`
        ORDER BY
            NULL
        LIMIT
            1
    )
GROUP BY
    `myapp_organization`.`id`
ORDER BY
    `myapp_organization`.`name` ASC,
    `myapp_organization`.`id` DESC;

-- -> Sort: myapp_organization.id DESC
--     -> Stream results  (cost=12504019.30 rows=124999993)
--         -> Remove duplicate (myapp_organization, myapp_member) rows using temporary table (weedout)  (cost=12504019.30 rows=124999993)
--             -> Filter: ((U0.`name` like '%a%') or (U2.`name` like '%a%'))  (cost=12504019.30 rows=124999993)
--                 -> Left hash join (U0.id = U2.organization_id)  (cost=12504019.30 rows=124999993)
--                     -> Nested loop left join  (cost=25305.62 rows=250000)
--                         -> Nested loop left join  (cost=51.21 rows=500)
--                             -> Nested loop inner join  (cost=0.70 rows=1)
--                                 -> Table scan on myapp_organization  (cost=0.35 rows=1)
--                                 -> Single-row index lookup on U0 using PRIMARY (id=myapp_organization.id)  (cost=0.35 rows=1)
--                             -> Index lookup on myapp_member using myapp_member_organization_id_417de06d_fk_myapp_organization_id (organization_id=myapp_organization.id)  (cost=50.51 rows=500)
--                         -> Filter: (U0.id = U1.organization_id)  (cost=0.61 rows=500)
--                             -> Index lookup on U1 using myapp_member_organization_id_417de06d_fk_myapp_organization_id (organization_id=myapp_organization.id)  (cost=0.61 rows=500)
--                     -> Hash
--                         -> Table scan on U2  (cost=2034.65 rows=500)