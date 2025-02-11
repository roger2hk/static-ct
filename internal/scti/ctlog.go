package scti

import (
	"context"
	"crypto"
	"crypto/ecdsa"
	"errors"
	"fmt"

	"github.com/google/certificate-transparency-go/x509"
	"github.com/transparency-dev/static-ct/internal/types"
	"github.com/transparency-dev/static-ct/modules/dedup"
	"github.com/transparency-dev/static-ct/storage"
	tessera "github.com/transparency-dev/trillian-tessera"
	"github.com/transparency-dev/trillian-tessera/ctonly"
	"k8s.io/klog/v2"
)

// log provides objects and functions to implement static-ct-api write api.
// TODO(phboneff): consider moving to methods.
type log struct {
	// origin identifies the log. It will be used in its checkpoint, and
	// is also its submission prefix, as per https://c2sp.org/static-ct-api.
	origin string
	// signSCT Signs SCTs.
	signSCT signSCT
	// chainValidationOpts contains various parameters for certificate chain
	// validation.
	chainValidationOpts ChainValidationOpts
	// storage stores certificate data.
	storage Storage
}

// Storage provides functions to store certificates in a static-ct-api log.
type Storage interface {
	// Add assigns an index to the provided Entry, stages the entry for integration, and returns a future for the assigned index.
	Add(context.Context, *ctonly.Entry) tessera.IndexFuture
	// AddIssuerChain stores every the chain certificate in a content-addressable store under their sha256 hash.
	AddIssuerChain(context.Context, []*x509.Certificate) error
	// AddCertDedupInfo stores the SCTDedupInfo of certificate in a log under its hash.
	AddCertDedupInfo(context.Context, *x509.Certificate, dedup.SCTDedupInfo) error
	// GetCertDedupInfo gets the SCTDedupInfo of certificate in a log from its hash.
	GetCertDedupInfo(context.Context, *x509.Certificate) (dedup.SCTDedupInfo, bool, error)
}

// NewLog instantiates a new log instance, with write endpoints.
// It initiates chain validation to validate writes, and storage to persist
// chains.
func NewLog(ctx context.Context, origin string, signer crypto.Signer, cvOpts ChainValidationOpts, cs storage.CreateStorage, ts TimeSource) (*log, error) {
	log := &log{}

	if origin == "" {
		return nil, errors.New("empty origin")
	}
	log.origin = origin

	// Validate signer that only ECDSA is supported.
	if signer == nil {
		return nil, errors.New("empty signer")
	}
	switch keyType := signer.Public().(type) {
	case *ecdsa.PublicKey:
	default:
		return nil, fmt.Errorf("unsupported key type: %v", keyType)
	}

	log.signSCT = func(leaf *types.MerkleTreeLeaf) (*types.SignedCertificateTimestamp, error) {
		return buildV1SCT(signer, leaf)
	}

	log.chainValidationOpts = cvOpts

	cpSigner, err := NewCpSigner(signer, origin, ts)
	if err != nil {
		klog.Exitf("failed to create checkpoint Signer: %v", err)
	}

	storage, err := cs(ctx, cpSigner)
	if err != nil {
		klog.Exitf("failed to initiate storage backend: %v", err)
	}
	log.storage = storage

	return log, nil
}
