#!/usr/bin/env bash

# iso8016时间格式
2022-09-09T00:00:00Z

# ISO 8601 format to a number of seconds since the Unix epoch (1970-01-01T00:00:00Z)
echo '"2022-09-09T00:00:00Z"'|jq 'fromdate'
1662681600

# 时间秒转换为iso8016时间
echo '1662681600' | jq 'todate'
"2022-09-09T00:00:00Z"

# iso8616格式输出现在的UTC时间
echo 'null'|jq 'now|todate'
"2022-06-29T02:59:52Z"

# iso8616格式输出现在的本地时区时间
echo 'null'|jq 'now|localtime|todate'
"2022-06-29T11:00:07Z"

# fromdate->秒->strftime进行格式化
echo '"2022-09-09T00:00:00Z"'|jq 'fromdate|strftime("%Y-%m-%d %H:%M:%S.000Z")'
"2022-09-09 00:00:00.000Z"

echo '"2022-09-09T00:00:00Z"'|jq 'fromdate|strftime("%Y-%m-%d %H:%M:%S")'
"2022-09-09 00:00:00"

# strptime-特定时间格式将字符串转换为时间类型
echo '"2022-09-09T00:00:00Z"'|jq 'strptime("%Y-%m-%dT%H:%M:%SZ")'
[
  2022,
  8,
  9,
  0,
  0,
  0,
  5,
  251
]
