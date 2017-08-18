package main

import "os"
import "fmt"
import "github.com/urfave/cli"

func main() {
	app := cli.NewApp()
	app.Name = "extropy"
	app.Usage = "reduce entropy by updating a CloudFormation Template from Live Resources"

	app.Commands = []cli.Command{
		{
			Name:  "update-sg-template",
			Usage: "Update a Security Groups template.",
			Action: func(c *cli.Context) error {
				fmt.Println("Running update-sg-template...")
				fmt.Println("Finished!")
				return nil
			},
		},
	}

	app.Run(os.Args)
}
