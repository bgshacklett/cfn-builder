package cfn

import (
	"github.com/awslabs/goformation/cloudformation"
	"github.com/bgshacklett/extropy/aws"
	"github.com/yanatan16/itertools"
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

	// Get the Security Groups
	supportedResources := <-(itertools.Filter(
		func(resource) {
			resource.Type == "AWS::EC2::SecurityGroup"
		},
		original.Resources,
	))

	// Get the unsupported resources in a separate list
	unsupportedResources := <-(itertools.Filter(
		func(resource) {
			resource.Type != "AWS::EC2::SecurityGroup"
		},
		original.Resources,
	))

	// Get the physical ID for each Security Group
	physicalSupportedResourceIDs := <-(itertools.Map(
		func(item) {
			result, _ := cfnMapper.MapResource(region, stackName, item)
			return result
		},
		supportedResources,
	))

	// Get the current description of each supported resource by its Physical ID
	physicalResourceDescriptions := <-(itertools.Map(
		func(item) {
			result, _ := resourceDescriber.DescribeResource(item)
			return result
		},
		physicalSupportedResourceIDs,
	))

	// Translate the physical description into CloudFormation Resources
	updatedResources := <-(itertools.Map(
		func(item) {
			result, _ := resourceBuilder.Build(item)
			return result
		},
		physicalResourceDescriptions,
	))

	updatedTemplate := cloudformation.NewTemplate()

	return original, nil
}
