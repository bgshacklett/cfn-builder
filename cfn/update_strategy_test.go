package cfn

import (
	"encoding/json"
	"github.com/aws/aws-sdk-go/aws/arn"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/awslabs/goformation/cloudformation"
	"github.com/bgshacklett/extropy/aws"
	"github.com/stretchr/testify/assert"
	"io/ioutil"
	"testing"
)

func newTestTemplate(fileName string) (*cloudformation.Template, error) {

	template := cloudformation.NewTemplate()
	templateJSON, err := ioutil.ReadFile("./tests/" + fileName)
	json.Unmarshal(templateJSON, template)

	return template, err
}

func newTestSecurityGroup(fileName string) (*ec2.SecurityGroup, error) {

	securityGroup := new(ec2.SecurityGroup)
	securityGroupJSON, err := ioutil.ReadFile("./tests/" + fileName)
	json.Unmarshal(securityGroupJSON, securityGroup)

	return securityGroup, err
}

type testCfnMapper struct{ arn arn.ARN }

func (r *testCfnMapper) MapResource(
	region string,
	stackName string,
	resource string,
) (arn.ARN, error) {

	return arn.ARN{
			Partition: "arn",
			Service:   "svc",
			Region:    region,
			AccountID: "12345",
			Resource:  stackName + "/" + resource,
		},
		nil
}

type testSGDescriber struct{}

// DescribeResource gets information about a resource from the AWS API
func (r *testSGDescriber) DescribeResource(
	arn arn.ARN,
) (aws.Resource, error) {

	// Get a mock Security Group object.
	securityGroup, err := newTestSecurityGroup("sg_m.json")

	description := arn.String()
	groupID := "sg-xxxxxxxx"
	groupName := "GroupName"

	// Configure the object.
	securityGroup.Description = &description
	securityGroup.GroupId = &groupID
	securityGroup.GroupName = &groupName

	// Return the SecurityGroup
	return securityGroup, err
}

type testResourceBuilder struct{}

func (r *testResourceBuilder) Build(physicalResource) (aws.Resource, error) {

	// Get a mock Resource object based on the AWS resource returned above
	cfnResource := new(cloudformation.AWSEC2SecurityGroup)

	//
	return cfnResource, nil
}

func TestExecuteModified(t *testing.T) {

	// Create a new object to handle assertions
	assert := assert.New(t)

	fmtExecuteNoError := "Execute should not return an error."
	fmtExecuteMatchExpected := "Execute should return the expected result."

	/*
	 * Setup
	 */
	// Create instances of the original and expected templates
	orig, err := newTestTemplate("orig.template")
	assert.Nil(err, "newTestTemplate should not return an error for orig.")

	expected, err := newTestTemplate("mod_resource.template")
	assert.Nil(err, "newTestTemplate should not return an error for expected.")

	// Create instances of stubbed dependencies.
	cfnMapper := new(testCfnMapper)
	resourceDescriber := new(testSGDescriber)
	resourceBuilder := new(testResourceBuilder)

	// Create an instance of the system under test.
	updateStrategy := new(DefaultUpdateStrategy)

	/*
	 * Test
	 */
	actual, err := updateStrategy.Execute(
		"us-test-1", // Region
		orig,
		"modified", // Stack Name
		cfnMapper,
		resourceDescriber,
		resourceBuilder,
	)

	// Ensure that the method does not throw an error.
	assert.Nil(err, fmtExecuteNoError)

	// Ensure that the actual result matches the expected result.
	assert.Equal(expected, actual, fmtExecuteMatchExpected)
	/*
	 * Teardown
	 */
}
