package main

import (
	"context"
	"fmt"
	"log"
	"os"

	solana "github.com/gagliardetto/solana-go"
	"github.com/gagliardetto/solana-go/rpc"
	ucli "github.com/urfave/cli/v2"

	// loaderV3Bindings "github.com/base/loader-v3-go-bindings/bindings"
	mcmio "github.com/base/mcm-go/pkg/proposal/io"
)

func main() {
	app := &ucli.App{
		Name:  "generate-upgrade-instructions",
		Usage: "Generate Solana BPF Loader v3 upgrade instruction",
		Flags: []ucli.Flag{
			&ucli.StringFlag{
				Name:     "rpc-url",
				Usage:    "RPC URL to fetch on-chain data",
				Required: true,
			},
			&ucli.StringFlag{
				Name:     "program",
				Usage:    "Program account address",
				Required: true,
			},
			&ucli.StringFlag{
				Name:     "buffer",
				Usage:    "Buffer account address with new program data",
				Required: true,
			},
			&ucli.StringFlag{
				Name:     "spill",
				Usage:    "Spill account address to receive refunded lamports",
				Required: true,
			},
			&ucli.StringFlag{
				Name:  "output",
				Usage: "Output JSON file path",
				Value: "upgrade_instruction.json",
			},
		},
		Action: func(c *ucli.Context) error {
			params := parseCliParams(c)

			// Derive ProgramData PDA from program address
			programData, _, err := solana.FindProgramAddress(
				[][]byte{params.program.Bytes()},
				solana.BPFLoaderUpgradeableProgramID,
			)
			if err != nil {
				return fmt.Errorf("failed to derive program data address: %w", err)
			}
			fmt.Println("programData", programData)

			// Fetch program and buffer authorities from on-chain
			ctx := context.Background()
			client := rpc.New(params.rpcURL)

			// Fetch program account to get authority
			programAccountInfo, err := client.GetAccountInfo(ctx, params.program)
			if err != nil {
				return fmt.Errorf("failed to fetch program account: %w", err)
			}
			if programAccountInfo == nil || programAccountInfo.Value == nil {
				return fmt.Errorf("program account not found")
			}

			// Fetch program data account to get upgrade authority
			programDataAccountInfo, err := client.GetAccountInfo(ctx, programData)
			if err != nil {
				return fmt.Errorf("failed to fetch program data account: %w", err)
			}
			if programDataAccountInfo == nil || programDataAccountInfo.Value == nil {
				return fmt.Errorf("program data account not found")
			}

			// Parse upgrade authority from program data account
			// ProgramData account layout: [discriminator(4), slot(8), upgrade_authority(32), ...]
			programDataBytes := programDataAccountInfo.Value.Data.GetBinary()
			if len(programDataBytes) < 45 {
				return fmt.Errorf("invalid program data account size")
			}

			// Check if authority is present (option discriminator at byte 12)
			hasAuthority := programDataBytes[12] == 1
			if !hasAuthority {
				return fmt.Errorf("program has no upgrade authority")
			}

			// Extract authority pubkey (bytes 13-45)
			var upgradeAuthority solana.PublicKey
			copy(upgradeAuthority[:], programDataBytes[13:45])
			fmt.Println("upgrade authority", upgradeAuthority)

			// Fetch buffer account to validate authority
			bufferAccountInfo, err := client.GetAccountInfo(ctx, params.buffer)
			if err != nil {
				return fmt.Errorf("failed to fetch buffer account: %w", err)
			}
			if bufferAccountInfo == nil || bufferAccountInfo.Value == nil {
				return fmt.Errorf("buffer account not found")
			}

			// Parse buffer authority
			// Buffer account layout: [discriminator(4), authority(32), ...]
			bufferBytes := bufferAccountInfo.Value.Data.GetBinary()
			if len(bufferBytes) < 37 {
				return fmt.Errorf("invalid buffer account size")
			}

			// Check if buffer authority is present (option discriminator at byte 4)
			hasBufferAuthority := bufferBytes[4] == 1
			if !hasBufferAuthority {
				return fmt.Errorf("buffer has no authority")
			}

			// Extract buffer authority pubkey (bytes 5-37)
			var bufferAuthority solana.PublicKey
			copy(bufferAuthority[:], bufferBytes[5:37])
			fmt.Println("buffer authority", bufferAuthority)

			// Validate that program authority and buffer authority match
			if upgradeAuthority != bufferAuthority {
				return fmt.Errorf("program authority (%s) does not match buffer authority (%s)", upgradeAuthority, bufferAuthority)
			}

			// // Create upgrade instruction using bindings
			// upgradeIx, err := loaderV3Bindings.NewUpgradeInstruction(
			// 	programData,
			// 	program,
			// 	buffer,
			// 	spill,
			// 	solana.SysVarRentPubkey,
			// 	solana.SysVarClockPubkey,
			// 	authority,
			// )
			// if err != nil {
			// 	return fmt.Errorf("failed to create upgrade instruction: %w", err)
			// }

			// // Convert to GenericInstruction
			// data, err := upgradeIx.Data()
			// if err != nil {
			// 	return fmt.Errorf("failed to serialize instruction data: %w", err)
			// }

			genericIx := &solana.GenericInstruction{
				// ProgID: solana.BPFLoaderUpgradeableProgramID,
				// AccountValues: upgradeIx.AccountMetaSlice,
				// DataBytes:     data,
			}

			// Save using mcm-go SDK
			instructions := []solana.Instruction{genericIx}
			if err := mcmio.SaveInstructions(instructions, params.output); err != nil {
				return fmt.Errorf("failed to save instructions: %w", err)
			}

			fmt.Printf("Upgrade instruction written to %s\n", params.output)
			fmt.Printf("Program: %s\n", params.program)
			fmt.Printf("ProgramData (derived): %s\n", programData)
			fmt.Printf("Buffer: %s\n", params.buffer)
			fmt.Printf("Spill: %s\n", params.spill)
			fmt.Printf("Authority: %s\n", upgradeAuthority)
			return nil
		},
	}

	if err := app.Run(os.Args); err != nil {
		log.Fatal(err)
	}
}

type cliParams struct {
	rpcURL  string
	program solana.PublicKey
	buffer  solana.PublicKey
	spill   solana.PublicKey
	output  string
}

func parseCliParams(c *ucli.Context) *cliParams {
	fmt.Println(" ---CLI params--- ")
	rpcURLInput := c.String("rpc-url")

	// Map cluster aliases to RPC URLs
	rpcURL := rpcURLInput
	switch rpcURLInput {
	case "devnet":
		rpcURL = "https://api.devnet.solana.com"
	case "testnet":
		rpcURL = "https://api.testnet.solana.com"
	case "mainnet", "mainnet-beta":
		rpcURL = "https://api.mainnet-beta.solana.com"
	}

	fmt.Println("rpc-url", rpcURL)
	program := solana.MustPublicKeyFromBase58(c.String("program"))
	fmt.Println("program", program)
	buffer := solana.MustPublicKeyFromBase58(c.String("buffer"))
	fmt.Println("buffer", buffer)
	spill := solana.MustPublicKeyFromBase58(c.String("spill"))
	fmt.Println("spill", spill)
	output := c.String("output")
	fmt.Println("output", output)
	fmt.Println(" ---------------- ")

	return &cliParams{
		rpcURL:  rpcURL,
		program: program,
		buffer:  buffer,
		spill:   spill,
		output:  output,
	}
}
