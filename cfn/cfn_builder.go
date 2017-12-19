package cfn

import (
	"github.com/bgshacklett/extropy/aws"
	"github.com/awslabs/goformation/cloudformation"
	"github.com/bgshacklett/extropy/frames"
	"github.com/bgshacklett/extropy/aws/services"
	"encoding/json"
	"fmt"
)

// A ResourceBuilder builds CloudFormation Resources
type ResourceBuilder interface {
	Build(aws.Resource) (aws.Resource, error)
}



func SGBuilder(resources frames.SupportedResources, region string) (*cloudformation.Template, error) {
	template := cloudformation.NewTemplate()

	for i,_ := range resources {
		var resource aws.ResourceDescriber
		resource.DescribeResource(resources[i], region)

		var sg services.SG
		var ingressRules []cloudformation.AWSEC2SecurityGroup_Ingress
		var egressRules  []cloudformation.AWSEC2SecurityGroup_Egress
		// Remarshal our resource into the struct
		res,err := json.Marshal(resource.Description)
		if err != nil {
			return nil, err
		}
		json.Unmarshal(res, &sg)


		for i := range sg.IpPermissionsEgress {
			egress := sg.IpPermissionsEgress[i]
			for ii := range egress.IpRanges {
				ip := egress.IpRanges[ii]
				egressRules = append(egressRules, cloudformation.AWSEC2SecurityGroup_Egress{
					CidrIp: ip.CidrIp,
					ToPort: egress.ToPort,
					FromPort: egress.FromPort,
					IpProtocol: egress.IpProtocol,

				})
			}
		}

		for i := range sg.IpPermissions {
			ingress := sg.IpPermissions[i]
			for ii := range ingress.IpRanges {
				ip := ingress.IpRanges[ii]
				ingressRules = append(ingressRules, cloudformation.AWSEC2SecurityGroup_Ingress{
					CidrIp: ip.CidrIp,
					ToPort: ingress.ToPort,
					FromPort: ingress.FromPort,
					IpProtocol: ingress.IpProtocol,
				})
			}
		}

		template.Resources[resources[i].LogicalResourceId]  = &cloudformation.AWSEC2SecurityGroup{
			GroupDescription: sg.Description,
			VpcId: sg.VpcId,
			SecurityGroupIngress: ingressRules,
			SecurityGroupEgress: egressRules,
		}

		//fmt.Println(resource.Description)
	}



	j, err := template.JSON()
	fmt.Println()
	if err != nil {
		fmt.Printf("Failed to generate JSON: %s\n", err)
	} else {
		fmt.Printf("%s\n", string(j))
	}



	return template, nil
}