package cfn

import (
	"github.com/bgshacklett/extropy/aws"
	"github.com/awslabs/goformation/cloudformation"
	"github.com/bgshacklett/extropy/frames"
	"github.com/bgshacklett/extropy/aws/services"
	"encoding/json"
)

// A ResourceBuilder builds CloudFormation Resources
type ResourceBuilder interface {
	Build(aws.Resource) (aws.Resource, error)
}

func BuildTemplate(

	resources frames.SupportedResources,
	region string,

	) (*cloudformation.Template, error) {

	template := cloudformation.NewTemplate()

	// Generate template code for each resource
	for i := range resources {
		resource := resources[i]
		switch resource.ResourceType {
		case "AWS::EC2::SecurityGroup":
			res,err := securityGroup(resource, region)
			if err != nil {
				return nil, err
			}

			template.Resources[resource.LogicalResourceId] = res

		}
	}

	return template, nil
}

func securityGroup(

	resource frames.SupportedResource,
	region string,

) (interface{}, error) {

	// Some vars
	var sg services.SecurityGroup
	var ingressRules []cloudformation.AWSEC2SecurityGroup_Ingress
	var egressRules  []cloudformation.AWSEC2SecurityGroup_Egress
	var resourceCast aws.Resource

	// Describe the resource we're working with
	resourceCast.DescribeResource(resource, region)

	// Remarshal our resource into securitygroup struct
	res,err := json.Marshal(resourceCast.APIDescription)
	if err != nil {
		return nil, err
	}
	json.Unmarshal(res, &sg)

	// Create egress rules
	for i := range sg.IpPermissionsEgress {
		egress := sg.IpPermissionsEgress[i]
		for ii := range egress.IpRanges {
			ip := egress.IpRanges[ii]
			if ip.CidrIp == "0.0.0.0/0" && egress.IpProtocol == "-1" {
				break
			}
			egressRules = append(egressRules, cloudformation.AWSEC2SecurityGroup_Egress{
				CidrIp: ip.CidrIp,
				ToPort: egress.ToPort,
				FromPort: egress.FromPort,
				IpProtocol: egress.IpProtocol,

			})
		}
		for ii := range egress.Ipv6Ranges {
			ip := egress.Ipv6Ranges[ii]
			egressRules = append(egressRules, cloudformation.AWSEC2SecurityGroup_Egress{
				CidrIp: ip.CidrIpv6,
				Description: ip.Description,
				ToPort: egress.ToPort,
				FromPort: egress.FromPort,
				IpProtocol: egress.IpProtocol,
			})
		}
		/* TODO: figure out SG destination egress - needs example
		for ii := range egress.UserIdGroupPairs {
			gp := egress.UserIdGroupPairs[ii]
			egressRules = append(egressRules, cloudformation.AWSEC2SecurityGroup_Egress{
				SourceSecurityGroupId: gp.GroupId,
				SourceSecurityGroupOwnerId: gp.UserId,
				ToPort: egress.ToPort,
				FromPort: egress.FromPort,
				IpProtocol: egress.IpProtocol,
			})
		}
		*/
	}
	// Create ingress rules
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
		for ii := range ingress.Ipv6Ranges {
			ip := ingress.Ipv6Ranges[ii]
			ingressRules = append(ingressRules, cloudformation.AWSEC2SecurityGroup_Ingress{
				CidrIp: ip.CidrIpv6,
				Description: ip.Description,
				ToPort: ingress.ToPort,
				FromPort: ingress.FromPort,
				IpProtocol: ingress.IpProtocol,
			})
		}
		for ii := range ingress.UserIdGroupPairs {
			gp := ingress.UserIdGroupPairs[ii]
			ingressRules = append(ingressRules, cloudformation.AWSEC2SecurityGroup_Ingress{
				SourceSecurityGroupId: gp.GroupId,
				SourceSecurityGroupOwnerId: gp.UserId,
				ToPort: ingress.ToPort,
				FromPort: ingress.FromPort,
				IpProtocol: ingress.IpProtocol,
			})
		}
	}

	// Create the resource
	templateResource  := &cloudformation.AWSEC2SecurityGroup{
		GroupDescription: sg.Description,
		VpcId: sg.VpcId,
		SecurityGroupIngress: ingressRules,
		SecurityGroupEgress: egressRules,
	}

	return templateResource, nil
}
