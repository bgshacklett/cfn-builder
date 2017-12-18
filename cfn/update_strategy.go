package cfn

import (
	"github.com/awslabs/goformation/cloudformation"
	"github.com/bgshacklett/extropy/aws"
	"github.com/yanatan16/itertools"
	"fmt"
)

// TemplateUpdateStrategy defines an interface for functions which
// intend to update CloudFormation templates from a live environment.
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

// DefaultUpdateStrategy currently returns a bogus string on execution.
type DefaultUpdateStrategy struct{}

// Execute implements the Execute
func (r *DefaultUpdateStrategy) Execute(

	region string,
	original *cloudformation.Template,
	stackName string,
	cfnMapper aws.CfnMapper,
	resourceDescriber aws.ResourceDescriber,

) (*cloudformation.Template, error) {
	var resourceBuilder ResourceBuilder
	//type resource aws.Resource
	resources := itertools.New(original.Resources)
	type resourceType map[string]interface{}
	// Get the Security Groups
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

	// Get the physical ID for each Security Group
	physicalSupportedResourceIDs := <-(itertools.Map(
		func(item interface{}) interface{} {
			result, _ := cfnMapper.MapResource(region, stackName, item.(string))
			return result
		},
		itertools.New(supportedResources),
	))

	// Get the current description of each supported resource by its Physical ID
	physicalResourceDescriptions := <-(itertools.Map(
		func(item interface{}) interface{} {
			result := resourceDescriber.DescribeResource(item.(string))
			return result
		},
		itertools.New(physicalSupportedResourceIDs),
	))

	// Translate the physical description into CloudFormation Resources
	updatedResources := <-(itertools.Map(
		func(item interface{}) interface{} {
			result, _ := resourceBuilder.Build(item)
			return result
		},
		itertools.New(physicalResourceDescriptions),
	))
	fmt.Println(updatedResources)

	updatedTemplate := cloudformation.NewTemplate()
	fmt.Println(updatedTemplate)

	return original, nil
}
