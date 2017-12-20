package cfn

import (
	"github.com/awslabs/goformation/cloudformation"
	"github.com/bgshacklett/extropy/aws"
	"github.com/yanatan16/itertools"
	"fmt"
	"github.com/bgshacklett/extropy/frames"
)

// TemplateUpdateStrategy defines an interface for functions which
// intend to update CloudFormation templates from a live environment.
//type TemplateUpdateStrategy func(interface{}) (*cloudformation.Template, error)
type TemplateUpdateStrategy func(
	//path string,
	stackName string,
	region string,
	supportedResources *frames.SupportedResources,
	original *cloudformation.Template,
	updatedTemplate *cloudformation.Template,
) (interface{}, error)
/*
type TemplateUpdateStrategy interface {

	Execute(

		region string,
		original *cloudformation.Template,
		stackName string,
		cfnMapper aws.CfnMapper,
		resourceDescriber aws.ResourceDescriber,
		resourceBuilder ResourceBuilder,

	) (*cloudformation.Template, error)

}
*/
// DefaultUpdateStrategy currently returns a bogus string on execution.
//type DefaultUpdateStrategy struct{}

// Execute implements the Execute
func DefaultUpdateStrategy(

	//path string,
	stackName string,
	region string,
	supportedResources *frames.SupportedResources,
	original *cloudformation.Template,
	updatedTemplate *cloudformation.Template,

	//cfnMapper aws.CfnMapper,
	//resourceDescriber aws.ResourceDescriber,

) (interface{}, error) {

	//var resourceBuilder ResourceBuilder
	var cfnMapper aws.CfnMapper
	//var resourceDescriber aws.ResourceDescriber
	finalTemplate := cloudformation.NewTemplate()

	//type resource aws.Resource
	//resources := itertools.New(original.Resources)


	// Get the Security Groups
	/*
	supportedResources := <-(itertools.Filter(
		func(resource interface{}) bool {
			mappedResource := resource.(map[string]interface{})
			isType := mappedResource["Type"] == "AWS::EC2::SecurityGroup"
			return isType
		},
		resources,
	))


	// Get the unsupported resources in a separate list
	unsupportedResources := <-(itertools.Filter(
		func(resource interface{}) bool {
			mappedResource := resource.(map[string]interface{})
			isType := mappedResource["Type"] != "AWS::EC2::SecurityGroup"
			return isType
		},
		resources,
	))

	fmt.Println(unsupportedResources)
	*/

	// Get the physical ID for each Security Group
	physicalSupportedResourceIDs := <-(itertools.Map(
		func(item interface{}) interface{} {
			result, _ := cfnMapper.MapResource(region, stackName, item.(string))
			return result
		},
		itertools.New(supportedResources),
	))

	// todo: FIX THIS ONE LATER
	// Get the current description of each supported resource by its Physical ID
	physicalResourceDescriptions := <-(itertools.Map(
		func(item interface{}) interface{} {
			//result := resourceDescriber.DescribeResource(item.(string))
			return true
		},
		itertools.New(physicalSupportedResourceIDs),
	))


	/*
	// Translate the physical description into CloudFormation Resources
	updatedResources := <-(itertools.Map(
		func(item interface{}) interface{} {
			result, _ := resourceBuilder.Build(item)
			return result
		},
		itertools.New(physicalResourceDescriptions),
	))
	*/


	fmt.Println(physicalResourceDescriptions)
	fmt.Println(finalTemplate)

	return original, nil
}
