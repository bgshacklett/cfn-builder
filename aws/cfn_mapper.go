package aws

import (
	"github.com/aws/aws-sdk-go/aws/arn"
	"github.com/bgshacklett/extropy/frames"
	"github.com/yanatan16/itertools"
	"encoding/json"
	"github.com/aws/aws-sdk-go/service/cloudformation"

)

type LogicalResources []LogicalResource

type LogicalResource struct {
	Code

}


type CfnMapper interface {
	MapResource(
		region string,
		stackName string,
		resource string,
	) (arn.ARN, error)
}


func GetSupportedResources(region string, stackName string) (*frames.SupportedResources, error) {

	// get all resources created from the stack
	stackResourcesOutput, err := GetStackResources(region, stackName)
	if err != nil {
		return nil, err
	}

	// list of supported types
	supportedTypes := []string{
		"AWS::EC2::SecurityGroup",
	}

	// create iter object and filter out any unsupported resources
	resourcesIter := itertools.New(stackResourcesOutput.StackResources)
	resourceSupported := <-(itertools.Filter(
		func(resource interface{}) bool {
			mappedResource := resource.([]*cloudformation.StackResource)
			for t := range supportedTypes {
				if *mappedResource[0].ResourceType == supportedTypes[t] {
					return true
				}
			}
			return false
		},
		resourcesIter,
	))
	raw,err := json.Marshal(resourceSupported)
	if err != nil {
		return nil, err
	}
	supportedResources := &frames.SupportedResources{}
	json.Unmarshal(raw, supportedResources)

	return supportedResources, nil
}