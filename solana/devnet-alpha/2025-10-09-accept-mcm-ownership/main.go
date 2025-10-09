package main

import (
	"encoding/hex"
	"fmt"
	"log"
	"os"

	solana "github.com/gagliardetto/solana-go"
	ucli "github.com/urfave/cli/v2"

	mcmHex "github.com/base/mcm-go/pkg/hex"
	mcmInstructions "github.com/base/mcm-go/pkg/instructions"
	mcmpda "github.com/base/mcm-go/pkg/pda"
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
			&ucli.StringFlag{
				Name:     "multisig-id",
				Usage:    "Multisig ID (32-byte hex string, with 0x prefix)",
				Required: true,
			},
			&ucli.StringFlag{
				Name:     "mcm-program-id",
				Usage:    "MCM program ID (base58 encoded)",
				Required: true,
			},
		},
		Action: func(c *ucli.Context) error {
			// Parse CLI parameters
			params, err := parseCliParams(c)
			if err != nil {
				return err
			}

			mcmAuthority, _, err := mcmpda.MultisigSignerPDA(params.mcmProgramID, params.multisigID)
			if err != nil {
				return fmt.Errorf("failed to derive multisig authority PDA: %w", err)
			}
			fmt.Printf("mcmAuthority: %s\n", mcmAuthority)

			proposalIxs := make([]solana.Instruction, 0)

			// Accept ownership instruction
			acceptOwnershipIx, err := mcmInstructions.AcceptOwnership(mcmInstructions.AcceptOwnershipParams{
				MultisigID: params.multisigID,
				Authority:  mcmAuthority,
				ProgramID:  params.mcmProgramID,
			})
			if err != nil {
				return fmt.Errorf("failed to create accept ownership instruction: %w", err)
			}
			proposalIxs = append(proposalIxs, acceptOwnershipIx)

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
	ixsOutput    string
	mcmProgramID solana.PublicKey
	multisigID   [32]byte
}

func parseCliParams(c *ucli.Context) (*cliParams, error) {
	fmt.Println(" ---CLI params--- ")

	// Parse ixs output
	ixsOutput := c.String("ixs-output")
	fmt.Printf("ixs-output: %s\n", ixsOutput)

	// Parse program ID
	mcmProgramID := solana.MustPublicKeyFromBase58(c.String("mcm-program-id"))
	fmt.Println("mcm-program-id:", mcmProgramID)

	// Parse multisig ID
	multisigID, err := mcmHex.Parse32(c.String("multisig-id"))
	if err != nil {
		return nil, fmt.Errorf("failed to decode multisig ID: %w", err)
	}
	fmt.Printf("multisig-id: %s\n", hex.EncodeToString(multisigID[:]))

	fmt.Println(" ---------------- ")

	return &cliParams{
		ixsOutput:    ixsOutput,
		mcmProgramID: mcmProgramID,
		multisigID:   multisigID,
	}, nil
}
