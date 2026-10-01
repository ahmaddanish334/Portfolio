USE f1_analytics;

DROP FUNCTION IF EXISTS clean_text;
DROP FUNCTION IF EXISTS f1_time_ms;

DELIMITER $$

CREATE FUNCTION clean_text(v TEXT)
RETURNS TEXT
DETERMINISTIC
NO SQL
BEGIN
    IF v IS NULL OR TRIM(v) = '' OR TRIM(v) = '\\N' THEN
        RETURN NULL;
    END IF;
    RETURN TRIM(v);
END$$

CREATE FUNCTION f1_time_ms(v TEXT)
RETURNS BIGINT
DETERMINISTIC
NO SQL
BEGIN
    DECLARE x TEXT;
    DECLARE colon_count INT;
    DECLARE hours_part DECIMAL(12,3) DEFAULT 0;
    DECLARE minutes_part DECIMAL(12,3) DEFAULT 0;
    DECLARE seconds_part DECIMAL(12,3) DEFAULT 0;

    SET x = clean_text(v);

    IF x IS NULL THEN
        RETURN NULL;
    END IF;

    SET colon_count = LENGTH(x) - LENGTH(REPLACE(x, ':', ''));

    IF colon_count = 1 THEN
        SET minutes_part = CAST(SUBSTRING_INDEX(x, ':', 1) AS DECIMAL(12,3));
        SET seconds_part = CAST(SUBSTRING_INDEX(x, ':', -1) AS DECIMAL(12,3));
    ELSEIF colon_count = 2 THEN
        SET hours_part = CAST(SUBSTRING_INDEX(x, ':', 1) AS DECIMAL(12,3));
        SET minutes_part = CAST(
            SUBSTRING_INDEX(SUBSTRING_INDEX(x, ':', 2), ':', -1)
            AS DECIMAL(12,3)
        );
        SET seconds_part = CAST(SUBSTRING_INDEX(x, ':', -1) AS DECIMAL(12,3));
    ELSE
        RETURN NULL;
    END IF;

    RETURN ROUND(
        hours_part * 3600000
        + minutes_part * 60000
        + seconds_part * 1000
    );
END$$

DELIMITER ;
