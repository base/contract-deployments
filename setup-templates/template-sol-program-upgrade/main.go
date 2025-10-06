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
	// "github.com/base/mcm-go/pkg/proposal/io"
)

func main() {
	app := &ucli.App{
		Name:  "generate-upgrade-instructions",
		Usage: "Generate Solana BPF Loader v3 upgrade instruction",
		Flags: []ucli.Flag{
			&ucli.StringFlag{
				Name:     "rpc",
				Aliases:  []string{"r"},
				Usage:    "RPC URL to fetch on-chain data",
				Required: true,
			},
			&ucli.StringFlag{
				Name:     "program",
				Aliases:  []string{"p"},
				Usage:    "Program account address",
				Required: true,
			},
			&ucli.StringFlag{
				Name:     "buffer",
				Aliases:  []string{"b"},
				Usage:    "Buffer account address with new program data",
				Required: true,
			},
			&ucli.StringFlag{
				Name:     "spill",
				Aliases:  []string{"s"},
				Usage:    "Spill account address to receive refunded lamports",
				Required: true,
			},
			&ucli.StringFlag{
				Name:    "output",
				Aliases: []string{"o"},
				Usage:   "Output JSON file path",
				Value:   "upgrade_instruction.json",
			},
		},
		Action: func(c *ucli.Context) error {
			fmt.Println(" ---CLI params--- ")
			rpcUrl := c.String("rpc")
			fmt.Println("rpcUrl", rpcUrl)
			program := solana.MustPublicKeyFromBase58(c.String("program"))
			fmt.Println("program", program)
			buffer := solana.MustPublicKeyFromBase58(c.String("buffer"))
			fmt.Println("buffer", buffer)
			fmt.Println(" ---------------- ")

			// Derive ProgramData PDA from program address
			programData, _, err := solana.FindProgramAddress(
				[][]byte{program.Bytes()},
				solana.MustPublicKeyFromBase58("BPFLoaderUpgradeab1e11111111111111111111111"),
			)
			if err != nil {
				return fmt.Errorf("failed to derive program data address: %w", err)
			}
			fmt.Println("programData", programData)

			// Fetch program and buffer authorities from on-chain
			ctx := context.Background()
			client := rpc.New(rpcUrl)

			// Fetch program account to get authority
			programAccountInfo, err := client.GetAccountInfo(ctx, program)
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
			bufferAccountInfo, err := client.GetAccountInfo(ctx, buffer)
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

			// genericIx := &solana.GenericInstruction{
			// 	ProgID:        upgradeIx.ProgramID(),
			// 	AccountValues: upgradeIx.AccountMetaSlice,
			// 	DataBytes:     data,
			// }

			// // Save using mcm-go SDK
			// instructions := []*solana.GenericInstruction{genericIx}
			// outputFile := c.String("output")
			// if err := io.SaveInstructions(instructions, outputFile); err != nil {
			// 	return fmt.Errorf("failed to save instructions: %w", err)
			// }

			// fmt.Printf("Upgrade instruction written to %s\n", outputFile)
			// fmt.Printf("Program: %s\n", program)
			// fmt.Printf("ProgramData (derived): %s\n", programData)
			// fmt.Printf("Buffer: %s\n", buffer)
			// fmt.Printf("Spill: %s\n", spill)
			// fmt.Printf("Authority: %s\n", authority)
			return nil
		},
	}

	if err := app.Run(os.Args); err != nil {
		log.Fatal(err)
	}
}
