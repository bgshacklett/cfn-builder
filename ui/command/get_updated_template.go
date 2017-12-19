package command

import (
	"github.com/bgshacklett/extropy/cfn"
	"io"

	"github.com/bgshacklett/extropy/aws"
	"github.com/yanatan16/itertools"
	"github.com/aws/aws-sdk-go/service/cloudformation"
	"encoding/json"
	"github.com/bgshacklett/extropy/frames"

)

// GetUpdatedTemplate handles the get-updated-template command.
func GetUpdatedTemplate(

	path string, // The path to the template
	stackName string, // The name of the associated stack
	region string, // The region where the associated stack resides
	outputWriter io.Writer, // The Writer for standard output
	updateStrategy cfn.TemplateUpdateStrategy, // Function to update the template

) error {
	supportedTypes := []string{
		"AWS::EC2::SecurityGroup",
	}

	/*
	// get template for stack
	originalTemplateBody, err := aws.GetGoformationTemplate(region, stackName)
	if err != nil {
		return err
	}
	*/
	// get all resources for stack
	stackResourcesOuput, err := aws.GetStackResources(region, stackName)
	if err != nil {
		return err
	}

	// TODO: MOVE LATER - get list of resources we support out of stack resources
	var supportedResources frames.SupportedResources
	for _, resource := range stackResourcesOuput.StackResources {
		resourceIter := itertools.New(resource)
		resourceSupported := <-(itertools.Filter(
			func(resource interface{}) bool {
				mappedResource := resource.(*cloudformation.StackResource)
				for t := range supportedTypes {
					if *mappedResource.ResourceType == supportedTypes[t] {
						return true
					}
				}
				return false
			},
			resourceIter,
		))
		raw,err := json.Marshal(resourceSupported)
		if err != nil {
			return err
		}
		res := &frames.SupportedResource{}
		json.Unmarshal(raw, res)

		supportedResources = append(supportedResources, *res)
	}

	// TODO: MOVE LATER - Iterate over each resource resource.Description will hold the descirption
	for i,_ := range supportedResources {
		var resource aws.ResourceDescriber
		resource.DescribeResource(supportedResources[i], region)

		cfn.SGBuilder(resource, supportedResources[i])
		break
		//fmt.Println(resource.Description)
	}


	//res, err := originalTemplateBody.YAML()

	//_, err = fmt.Fprint(outputWriter, string(res))
	//

	/* TODO: Figure out update later

	updateStrategy Params:
	(
	path string,
	stackName string,
	region string,
	original *cloudformation.Template,
	)

	result, err := updateStrategy(path, stackName, region)
	if err != nil {
		return err
	}

	_, err = fmt.Fprint(outputWriter, result)
	*/
	return nil
}
