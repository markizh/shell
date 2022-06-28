#!/usr/bin/env bash

# 安装并配置 AWS CLI
if type aws > /dev/null 2>&1; then
    aws --version
else
    read -p "AWS CLI not found,please press enter to start install."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    sleep 5
    echo -e "please input Access key ID and Secret access key."
    echo -e "if not, please login account to obtain. reference document url:https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-creds"
    echo -e "after getting the information, manually enter 'aws configure'"
    aws configure
fi

# 查询开通的region
ec2_describe_regions(){
    aws ec2 describe-regions --output text | cut -f4  
}

#
ec2_describe_regions
read -p "please input default region: " region
region=$region
echo -e "设置默认 region: $region"
clear

# 查询指定region的实例信息
ec2_describe_instances(){
    aws ec2 describe-instances --region $region --query 'Reservations[*].Instances[*].{Instance:InstanceId,AZ:Placement.AvailabilityZone,InstanceType:InstanceType,Platform:Platform,State:State.Name,CPU:CpuOptions.CoreCount,IP:NetworkInterfaces[0].Association.PublicIp,Name:Tags[?Key==`Name`]|[0].Value}' --output table   
}

# 查询所有区域的实例信息
ec2_describe_instances_all_reginos(){
   for i in $(ec2_describe_regions)
   do
       echo "$i的实例信息如下: "
       aws ec2 describe-instances --region $i --query 'Reservations[*].Instances[*].{Instance:InstanceId,AZ:Placement.AvailabilityZone,InstanceType:InstanceType,Platform:Platform,State:State.Name,CPU:CpuOptions.CoreCount,IP:NetworkInterfaces[0].Association.PublicIp,Name:Tags[?Key==`Name`]|[0].Value}' --output table
       sleep 1
   done
}

# 查询实例类型
ec2_describe_instance_type(){
    read -p "please input instance type prefix[mac|t|m|a|r|x|p|g|i|d|h]: " ec2_type
    [[ -z "${ec2_type}" ]] && ec2_type="$ec2_type"
    aws ec2 describe-instance-types  --region $region --query 'InstanceTypes[*].{InstanceType:InstanceType,CPU:VCpuInfo.DefaultCores,RAM:MemoryInfo.SizeInMiB}' --filters "Name=instance-type,Values=$ec2_type*" --output table
}

# 查询密钥
ec2_describe_key_pairs(){
    aws ec2 describe-key-pairs --region $region --query 'KeyPairs[*].{KeyName:KeyName}' --output table    
}

# 创建密钥
ec2_create_key_pair(){
    read -p "Please enter the name to create the key: " key_name
    echo -e "Note: please save the generated private key"
    aws ec2 create-key-pair --region $region --key-name $key_name
}

# 删除密钥
ec2_del_key_pairs(){
    ec2_describe_key_pairs
    read -p "Please input need del key name: " key_name
    aws ec2 delete-key-pair  --region $region --key-name $key_name
}

# 导入密钥
ec2_import_key_pair(){
    read -p "Please input public key file: " key_file
    key_file=${key_file:-"/root/.ssh/id_rsa.pub"}
    echo "$key_file"
    read -p "Please input key name(the region key name must uniq): " key_name
    key_name=${key_name:-"${region}_key_1"}
    echo "$key_name"
    aws ec2 import-key-pair --key-name $key_name --public-key-material fileb://$key_file
}

# 镜像查询菜单
ec2_images_menu(){
cat <<-EOF
        1) Ubuntu
        2) CentOS
        3) Windows
        4) amazon linux 2
        q) exit
EOF
}

# 查询镜像
ec2_images(){
    while true
    do
        ec2_images_menu
        read -p "请输入选项，然后复制需要的ImageId: " platform
        clear
        case $platform in
            1)
                aws ec2 describe-images --region $region --owners 099720109477 --query 'reverse(sort_by(Images, &CreationDate))[?contains(Description, `UNSUPPORTED`) != `true`]|[?contains(Description, `amd64`) == `true`]|[0:10].{ImageId:ImageId,Description:Description}' --filters  "Name=description,Values=*Ubuntu*20*04*LTS*amd64*focal*image*build*on*" --output table
                ;;
            2)
                aws ec2 describe-images --region $region --filters  "Name=description,Values=*CentOS*x86_64*" --owners '125523088429' --query 'reverse(sort_by(Images, &CreationDate))[].{ImageId:ImageId,Description:Description}' --output table
                ;;
            3)
                aws ec2 describe-images --region $region --owners amazon --query 'reverse(sort_by(Images, &CreationDate))[0:10].{ImageId:ImageId,Description:Description}' --filters "Name=description,Values=*Microsoft*Windows*Server*2019*with*Desktop*Experience*Locale*" --output table
                ;;
            4)
                aws ec2 describe-images --region $region --filters "Name=name,Values=amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2" "Name=architecture,Values=x86_64" --query 'reverse(sort_by(Images, &CreationDate)[*].[CreationDate,Name,ImageId])' --output table
                ;;
            "")
                echo -e "请输入选项，然后复制需要的 ImageId: "
                ;;
           q)
                break
                ;;
            *)
                echo -e "请输入数字选项，然后复制需要的 ImageId: "
                ;;
          esac
    done       
}

# 终止实例
ec2-terminate-instances(){
    ec2_describe_instances
    read -p "Please input instance id: " id
    aws ec2 terminate-instances --region $region --instance-ids $id --query 'TerminatingInstances[*].{Instance:InstanceId,CurrentState:CurrentState.Name}' --output table
}

# 运行实例
ec2_run_instances(){
    ec2_images
    read -p "Please input image id: " image_id
    [[ -z "${image_id}" ]] && image_id=$image_id
    
    ec2_describe_instance_type
    read -p "Please input instance type: " instance_type
    [[ -z "${instance_type}" ]] && instance_type=$instance_type
    
    [[ -z $(ec2_describe_key_pairs) ]] && ec2_create_key_pair
    read -p "Please connection ssh key pairs name: " key_name
    read -p  "Please input open instance num: " count
    
    echo "image-id: $image_id"
    echo "instance-type: $instance_type"
    echo "key-name: $key_name"
    echo "count: $count"
    
    aws ec2 run-instances --region $region --image-id $image_id --count $count --instance-type $instance_type --key-name $key_name --query 'Instances[*].{Instance:InstanceId,AZ:Placement.AvailabilityZone,InstanceType:InstanceType,Platform:Platform,State:State.Name,CPU:CpuOptions.CoreCount,IP:NetworkInterfaces[0].Association.PublicIp,Name:Tags[?Key==`Name`]|[0].Value}' --output table
}

# 实例开机
ec2_open_instance(){
    ec2_describe_instances
    read -p "Please input instance id: " ids
    aws ec2 start-instances --region $region --instance-ids $ids
}

# 实例关机
ec2_shutdown_instance(){
    ec2_describe_instances
    read -p "Please input instance id: " ids
    aws ec2 stop-instances --region $region --instance-ids $ids
}

# 实例重启
ec2_restart_instance(){
    ec2_describe_instances
    read -p "Please input instance id: " ids
    aws ec2 reboot-instances --region $region --instance-ids $ids
}

# 查询安全组名称
ec2_describe_sg(){
    ec2_describe_instances
    aws ec2 describe-security-groups --region ap-southeast-1  --query "SecurityGroups[*].{GroupName:GroupName,GroupId:GroupId,VpcId:VpcId}" --output table
}
 
# 安全组开放端口
ec2_open_port(){
    ec2_describe_sg
    read -p "Please input security_group_name: " group_name
    group_name=${group_name:-"default"}
    read -p "Please input protocol: " protocol
    protocol=${protocol:-"-1"}
    read -p "Please input port: " port
    port=${port:-"0-65535"}
    read -p "Please input cidr: " cidr
    cidr=${cidr:-"0.0.0.0/0"}

    aws ec2 authorize-security-group-ingress --region $region --group-name $group_name --protocol $protocol --port $port --cidr $cidr
}

# 添加EIP
ec2_add_eip(){
    ec2_describe_instances
    read -p "Please input instance id: " ids
    new_ip=$(aws ec2 allocate-address --region $region --query 'PublicIp' --out text)
    aws ec2 associate-address --region $region --instance-id $ids --public-ip $new_ip
}

# 删除已经绑定的EIP
ec2_del_bind_eip(){
    ec2_describe_instances
    read -p "Please input instance id: " ids
    allocation_id=$(aws ec2 describe-addresses --region $region --query "Addresses[?InstanceId=='$ids'].AllocationId" --out text)

    if [ "$allocation_id" = "" ];then
        echo "当前实例没有绑定弹性IP"
    else
        aws ec2 describe-addresses --region $region --query "Addresses[?InstanceId=='$ids'].{InstanceId:InstanceId,PublicIp:PublicIp,AllocationId:AllocationId}" --out table
        read -p "是否删除已经绑定的EIP，请确认[Y|N]" option
        if [ "$option" = "Y" ] || [ "$option" = "y" ];then
            aws ec2 release-address --region $region --allocation-id  $allocation_id
        else
           echo "取消删除EIP"
        fi 
    fi
}

# 删除未绑定的EIP
ec2_del_no_bind_eip(){
    aws ec2 describe-addresses --region $region --query "Addresses[].{InstanceId:InstanceId,PublicIp:PublicIp,AllocationId:AllocationId}" --out table
    read -p "Please input allocationId: " allocation_id
    aws ec2 release-address --region $region --allocation-id  $allocation_id
}

# aws cli 操作菜单
aws_cli_menu(){
cat <<-EOF
    1)  list all region
    2)  list the region ec2 instance
    3)  list all region ec2 instance
    4)  list instance type
    5)  list key pairs
    6)  create key pair
    7)  del key pair
    8)  import key pair
    9)  list image id
    10) terminate ec2 instance
    11) run ec2 instance
    12) ec2_describe_sg
    13) ec2_open_instance
    14) ec2_shutdown_instance
    15) ec2_restart_instance
    16) ec2_open_port
    17) ec2_add_eip
    18) ec2_del_bind_eip
    19) ec2_del_no_bind_eip
    q)  exit
EOF
}

manage_ec2(){
    aws_cli_menu
while true
do  
    read -p "Please input num option: " option
    clear
    aws_cli_menu
    case $option in
        1)
            ec2_describe_regions
            ;;
        2)
            ec2_describe_instances
            ;;
        3)
            ec2_describe_instances_all_reginos
            ;;
        4)
            ec2_describe_intance_type
            ;;
        5)
            ec2_describe_key_pairs
            ;;
        6)
            ec2_create_key_pair
            ;;
        7)
            ec2_del_key_pairs
            ;;
        8)
            ec2_import_key_pair
            ;;
        9)
            ec2_images
            ;;
        10)
            ec2-terminate-instances
            ;;
        11)
            ec2_run_instances
            ;;
        12)
            ec2_describe_sg
            ;;
        13)
            ec2_open_instance
            ;;
        14)
            ec2_shutdown_instance
            ;;
        15)
            ec2_restart_instance
            ;;
        16)
            ec2_open_port
            ;;
        17)
            ec2_add_eip
            ;;
        18)
            ec2_del_bind_eip
            ;;
        19)
            ec2_del_no_bind_eip
            ;;
        q)
            exit
            ;;
    esac
done
}

manage_ec2
