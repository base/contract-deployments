package main

import (
	"fmt"
	"log"
	"os"

	solana "github.com/gagliardetto/solana-go"
	ucli "github.com/urfave/cli/v2"

	mcmio "github.com/base/mcm-go/pkg/proposal/io"
)

func main() {
	app := &ucli.App{
		Name:  "generate-generic-instructions",
		Usage: "Generate MCM generic instructions",
		Flags: []ucli.Flag{
			&ucli.StringFlag{
				Name:  "ixs-output",
				Usage: "Instructions output JSON file path",
				Value: "ixs.json",
			},
			// TODO: Add instructions flags
		},
		Action: func(c *ucli.Context) error {
			// Parse CLI parameters
			params, err := parseCliParams(c)
			if err != nil {
				return err
			}

			// TODO: Add instructions to proposalIxs
			proposalIxs := make([]solana.Instruction, 0)

			// Save instructions using mcm-go SDK
			fmt.Printf("\n💾 Saving instructions to %s...\n", params.ixsOutput)
			if err := mcmio.SaveInstructions(proposalIxs, params.ixsOutput); err != nil {
				return fmt.Errorf("failed to save instructions: %w", err)
			}
			fmt.Printf("\n✅ Generic instructions written to %s\n", params.ixsOutput)

			return nil
		},
	}

	if err := app.Run(os.Args); err != nil {
		log.Fatal(err)
	}
}

type cliParams struct {
	ixsOutput string
	// TODO: Add instructions flags
}

func parseCliParams(c *ucli.Context) (*cliParams, error) {
	fmt.Println(" ---CLI params--- ")

	// Parse ixs output
	ixsOutput := c.String("ixs-output")
	fmt.Printf("ixs-output: %s\n", ixsOutput)

	// TODO: Parse additional flags

	fmt.Println(" ---------------- ")

	return &cliParams{
		ixsOutput: ixsOutput,
	}, nil
}
