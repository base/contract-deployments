package main

import (
	"encoding/hex"
	"fmt"
	"log"
	"os"
	"strings"

	solana "github.com/gagliardetto/solana-go"
	ucli "github.com/urfave/cli/v2"

	mcmHex "github.com/base/mcm-go/pkg/hex"
	mcmInstructions "github.com/base/mcm-go/pkg/instructions"
	mcmpda "github.com/base/mcm-go/pkg/pda"
	mcmio "github.com/base/mcm-go/pkg/proposal/io"
)

func main() {
	app := &ucli.App{
		Name:  "generate-signers-update-instructions",
		Usage: "Generate MCM signers update instructions (initialize, append, finalize, setConfig)",
		Flags: []ucli.Flag{
			&ucli.StringFlag{
				Name:     "mcm-program-id",
				Aliases:  []string{"p"},
				Usage:    "MCM program ID (base58 encoded)",
				Required: true,
			},
			&ucli.StringFlag{
				Name:     "multisig-id",
				Aliases:  []string{"m"},
				Usage:    "Multisig ID (32-byte hex string, with 0x prefix)",
				Required: true,
			},
			&ucli.StringFlag{
				Name:     "new-signers",
				Aliases:  []string{"s"},
				Usage:    "Comma-separated list of new signer addresses (20 byetes hex string, with 0x prefix)",
				Required: true,
			},
			&ucli.StringFlag{
				Name:     "signer-groups",
				Usage:    "Comma-separated list of group indices for each signer (e.g., '0,0,1,1')",
				Required: true,
			},
			&ucli.StringFlag{
				Name:     "group-quorums",
				Usage:    "Comma-separated list of quorum thresholds for each group (e.g., '2,3')",
				Required: true,
			},
			&ucli.StringFlag{
				Name:     "group-parents",
				Usage:    "Comma-separated list of parent group indices (e.g., '0,0')",
				Required: true,
			},
			&ucli.BoolFlag{
				Name:    "clear-root",
				Aliases: []string{"c"},
				Usage:   "Clear existing root when setting config",
				Value:   false,
			},
			&ucli.StringFlag{
				Name:    "output",
				Aliases: []string{"o"},
				Usage:   "Output JSON file path",
				Value:   "signers_update_instructions.json",
			},
		},
		Action: func(c *ucli.Context) error {
			// Parse CLI parameters
			params, err := parseCliParams(c)
			if err != nil {
				return err
			}

			proposalIxs := make([]solana.Instruction, 0)

			mcmAuthority, _, err := mcmpda.MultisigSignerPDA(params.programID, params.multisigID)
			if err != nil {
				return fmt.Errorf("failed to derive multisig authority PDA: %w", err)
			}
			fmt.Printf("mcmAuthority: %s\n", mcmAuthority)

			// 1. Initialize signers instruction
			fmt.Println("\n1. Creating InitSigners instruction...")
			initSignersIx, err := mcmInstructions.InitSigners(mcmInstructions.InitSignersParams{
				MultisigID:   params.multisigID,
				TotalSigners: uint8(len(params.newSigners)),
				Authority:    mcmAuthority,
				ProgramID:    params.programID,
			})
			if err != nil {
				return fmt.Errorf("failed to create init signers instruction: %w", err)
			}
			fmt.Printf("   ✓ Total signers: %d\n", len(params.newSigners))
			proposalIxs = append(proposalIxs, initSignersIx)

			// 2. Append signers instructions
			// Split signers into chunks if needed (Solana transaction size limit)
			const maxSignersPerAppend = 10
			fmt.Printf("\n2. Creating AppendSigners instruction(s)...\n")
			for i := 0; i < len(params.newSigners); i += maxSignersPerAppend {
				end := min(i+maxSignersPerAppend, len(params.newSigners))
				signersChunk := params.newSigners[i:end]

				appendSignersIx, err := mcmInstructions.AppendSigners(mcmInstructions.AppendSignersParams{
					MultisigID:   params.multisigID,
					SignersBatch: signersChunk,
					Authority:    mcmAuthority,
					ProgramID:    params.programID,
				})
				if err != nil {
					return fmt.Errorf("failed to create append signers instruction: %w", err)
				}
				fmt.Printf("   ✓ Chunk %d: %d signers [%d:%d]\n", (i/maxSignersPerAppend)+1, len(signersChunk), i, end)
				proposalIxs = append(proposalIxs, appendSignersIx)
			}

			// 3. Finalize signers instruction
			fmt.Println("\n3. Creating FinalizeSigners instruction...")
			finalizeSignersIx, err := mcmInstructions.FinalizeSigners(mcmInstructions.FinalizeSignersParams{
				MultisigID: params.multisigID,
				Authority:  mcmAuthority,
				ProgramID:  params.programID,
			})
			if err != nil {
				return fmt.Errorf("failed to create finalize signers instruction: %w", err)
			}
			fmt.Println("   ✓ Finalize complete")
			proposalIxs = append(proposalIxs, finalizeSignersIx)

			// 4. SetConfig instruction
			fmt.Println("\n4. Creating SetConfig instruction...")
			setConfigIx, err := mcmInstructions.SetConfig(mcmInstructions.SetConfigParams{
				MultisigID:   params.multisigID,
				SignerGroups: params.signerGroups,
				GroupQuorums: params.groupQuorums,
				GroupParents: params.groupParents,
				ClearRoot:    params.clearRoot,
				Authority:    mcmAuthority,
				ProgramID:    params.programID,
			})
			if err != nil {
				return fmt.Errorf("failed to create set config instruction: %w", err)
			}
			fmt.Printf("   ✓ Groups: %d, Quorums: %v, Parents: %v, ClearRoot: %v\n", len(params.groupQuorums), params.groupQuorums, params.groupParents, params.clearRoot)
			proposalIxs = append(proposalIxs, setConfigIx)

			// Save instructions using mcm-go SDK
			fmt.Printf("\n💾 Saving instructions to %s...\n", params.output)
			if err := mcmio.SaveInstructions(proposalIxs, params.output); err != nil {
				return fmt.Errorf("failed to save instructions: %w", err)
			}
			fmt.Printf("\n✅ Signers update instructions written to %s\n", params.output)

			return nil
		},
	}

	if err := app.Run(os.Args); err != nil {
		log.Fatal(err)
	}
}

type cliParams struct {
	multisigID   [32]byte
	programID    solana.PublicKey
	newSigners   [][20]uint8
	signerGroups []uint8
	groupQuorums [32]uint8
	groupParents [32]uint8
	clearRoot    bool
	output       string
}

func parseCliParams(c *ucli.Context) (*cliParams, error) {
	fmt.Println(" ---CLI params--- ")

	// Parse multisig ID
	multisigID, err := mcmHex.Parse32(c.String("multisig-id"))
	if err != nil {
		return nil, fmt.Errorf("failed to decode multisig ID: %w", err)
	}
	fmt.Printf("multisig-id: %s\n", hex.EncodeToString(multisigID[:]))

	// Parse program ID
	programID := solana.MustPublicKeyFromBase58(c.String("mcm-program-id"))
	fmt.Println("mcm-program-id:", programID)

	// Parse new signers
	signersStr := c.String("new-signers")
	signerAddrs := strings.Split(signersStr, ",")
	newSigners := make([][20]uint8, 0, len(signerAddrs))
	for _, addr := range signerAddrs {
		signer, err := mcmHex.Parse20(addr)
		if err != nil {
			return nil, fmt.Errorf("failed to parse signer: %w", err)
		}
		newSigners = append(newSigners, signer)
	}
	fmt.Printf("new-signers: %d signers\n", len(newSigners))
	for i, signer := range newSigners {
		fmt.Printf("  [%d] %s\n", i, hex.EncodeToString(signer[:]))
	}

	// Parse signer groups
	signerGroupsStr := strings.Split(c.String("signer-groups"), ",")
	signerGroups := make([]uint8, 0, len(signerGroupsStr))
	for _, sg := range signerGroupsStr {
		sg = strings.TrimSpace(sg)
		var val uint8
		if _, err := fmt.Sscanf(sg, "%d", &val); err != nil {
			return nil, fmt.Errorf("failed to parse signer group: %w", err)
		}
		signerGroups = append(signerGroups, val)
	}
	if len(signerGroups) != len(newSigners) {
		return nil, fmt.Errorf("signer-groups length (%d) must match new-signers length (%d)", len(signerGroups), len(newSigners))
	}
	fmt.Printf("signer-groups: %v\n", signerGroups)

	// Parse group quorums
	groupQuorumsStr := strings.Split(c.String("group-quorums"), ",")
	if len(groupQuorumsStr) > 32 {
		return nil, fmt.Errorf("group-quorums length (%d) must be 32 or less", len(groupQuorumsStr))
	}

	var groupQuorums [32]uint8
	for i, gq := range groupQuorumsStr {
		gq = strings.TrimSpace(gq)
		var val uint8
		if _, err := fmt.Sscanf(gq, "%d", &val); err != nil {
			return nil, fmt.Errorf("failed to parse group quorum: %w", err)
		}
		groupQuorums[i] = val
	}
	fmt.Printf("group-quorums: %v\n", groupQuorums)

	// Parse group parents
	groupParentsStr := strings.Split(c.String("group-parents"), ",")
	if len(groupParentsStr) != len(groupQuorumsStr) {
		return nil, fmt.Errorf("group-parents length (%d) must match group-quorums length (%d)", len(groupParentsStr), len(groupQuorumsStr))
	}
	var groupParents [32]uint8
	for i, gp := range groupParentsStr {
		gp = strings.TrimSpace(gp)
		var val uint8
		if _, err := fmt.Sscanf(gp, "%d", &val); err != nil {
			return nil, fmt.Errorf("failed to parse group parent: %w", err)
		}
		groupParents[i] = val
	}
	fmt.Printf("group-parents: %v\n", groupParents)

	clearRoot := c.Bool("clear-root")
	output := c.String("output")

	fmt.Printf("clear-root: %v\n", clearRoot)
	fmt.Printf("output: %s\n", output)
	fmt.Println(" ---------------- ")

	return &cliParams{
		multisigID:   multisigID,
		programID:    programID,
		newSigners:   newSigners,
		signerGroups: signerGroups,
		groupQuorums: groupQuorums,
		groupParents: groupParents,
		clearRoot:    clearRoot,
		output:       output,
	}, nil
}
