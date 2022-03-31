// Code generated by entc, DO NOT EDIT.

package ent

import (
	"context"
	"fmt"
	"log"

	"github.com/dopedao/RYO/api/ent/migrate"

	"github.com/dopedao/RYO/api/ent/turn"

	"entgo.io/ent/dialect"
	"entgo.io/ent/dialect/sql"
)

// Client is the client that holds all ent builders.
type Client struct {
	config
	// Schema is the client for creating, migrating and dropping schema.
	Schema *migrate.Schema
	// Turn is the client for interacting with the Turn builders.
	Turn *TurnClient
	// additional fields for node api
	tables tables
}

// NewClient creates a new client configured with the given options.
func NewClient(opts ...Option) *Client {
	cfg := config{log: log.Println, hooks: &hooks{}}
	cfg.options(opts...)
	client := &Client{config: cfg}
	client.init()
	return client
}

func (c *Client) init() {
	c.Schema = migrate.NewSchema(c.driver)
	c.Turn = NewTurnClient(c.config)
}

// Open opens a database/sql.DB specified by the driver name and
// the data source name, and returns a new client attached to it.
// Optional parameters can be added for configuring the client.
func Open(driverName, dataSourceName string, options ...Option) (*Client, error) {
	switch driverName {
	case dialect.MySQL, dialect.Postgres, dialect.SQLite:
		drv, err := sql.Open(driverName, dataSourceName)
		if err != nil {
			return nil, err
		}
		return NewClient(append(options, Driver(drv))...), nil
	default:
		return nil, fmt.Errorf("unsupported driver: %q", driverName)
	}
}

// Tx returns a new transactional client. The provided context
// is used until the transaction is committed or rolled back.
func (c *Client) Tx(ctx context.Context) (*Tx, error) {
	if _, ok := c.driver.(*txDriver); ok {
		return nil, fmt.Errorf("ent: cannot start a transaction within a transaction")
	}
	tx, err := newTx(ctx, c.driver)
	if err != nil {
		return nil, fmt.Errorf("ent: starting a transaction: %w", err)
	}
	cfg := c.config
	cfg.driver = tx
	return &Tx{
		ctx:    ctx,
		config: cfg,
		Turn:   NewTurnClient(cfg),
	}, nil
}

// BeginTx returns a transactional client with specified options.
func (c *Client) BeginTx(ctx context.Context, opts *sql.TxOptions) (*Tx, error) {
	if _, ok := c.driver.(*txDriver); ok {
		return nil, fmt.Errorf("ent: cannot start a transaction within a transaction")
	}
	tx, err := c.driver.(interface {
		BeginTx(context.Context, *sql.TxOptions) (dialect.Tx, error)
	}).BeginTx(ctx, opts)
	if err != nil {
		return nil, fmt.Errorf("ent: starting a transaction: %w", err)
	}
	cfg := c.config
	cfg.driver = &txDriver{tx: tx, drv: c.driver}
	return &Tx{
		config: cfg,
		Turn:   NewTurnClient(cfg),
	}, nil
}

// Debug returns a new debug-client. It's used to get verbose logging on specific operations.
//
//	client.Debug().
//		Turn.
//		Query().
//		Count(ctx)
//
func (c *Client) Debug() *Client {
	if c.debug {
		return c
	}
	cfg := c.config
	cfg.driver = dialect.Debug(c.driver, c.log)
	client := &Client{config: cfg}
	client.init()
	return client
}

// Close closes the database connection and prevents new queries from starting.
func (c *Client) Close() error {
	return c.driver.Close()
}

// Use adds the mutation hooks to all the entity clients.
// In order to add hooks to a specific client, call: `client.Node.Use(...)`.
func (c *Client) Use(hooks ...Hook) {
	c.Turn.Use(hooks...)
}

// TurnClient is a client for the Turn schema.
type TurnClient struct {
	config
}

// NewTurnClient returns a client for the Turn from the given config.
func NewTurnClient(c config) *TurnClient {
	return &TurnClient{config: c}
}

// Use adds a list of mutation hooks to the hooks stack.
// A call to `Use(f, g, h)` equals to `turn.Hooks(f(g(h())))`.
func (c *TurnClient) Use(hooks ...Hook) {
	c.hooks.Turn = append(c.hooks.Turn, hooks...)
}

// Create returns a create builder for Turn.
func (c *TurnClient) Create() *TurnCreate {
	mutation := newTurnMutation(c.config, OpCreate)
	return &TurnCreate{config: c.config, hooks: c.Hooks(), mutation: mutation}
}

// CreateBulk returns a builder for creating a bulk of Turn entities.
func (c *TurnClient) CreateBulk(builders ...*TurnCreate) *TurnCreateBulk {
	return &TurnCreateBulk{config: c.config, builders: builders}
}

// Update returns an update builder for Turn.
func (c *TurnClient) Update() *TurnUpdate {
	mutation := newTurnMutation(c.config, OpUpdate)
	return &TurnUpdate{config: c.config, hooks: c.Hooks(), mutation: mutation}
}

// UpdateOne returns an update builder for the given entity.
func (c *TurnClient) UpdateOne(t *Turn) *TurnUpdateOne {
	mutation := newTurnMutation(c.config, OpUpdateOne, withTurn(t))
	return &TurnUpdateOne{config: c.config, hooks: c.Hooks(), mutation: mutation}
}

// UpdateOneID returns an update builder for the given id.
func (c *TurnClient) UpdateOneID(id int) *TurnUpdateOne {
	mutation := newTurnMutation(c.config, OpUpdateOne, withTurnID(id))
	return &TurnUpdateOne{config: c.config, hooks: c.Hooks(), mutation: mutation}
}

// Delete returns a delete builder for Turn.
func (c *TurnClient) Delete() *TurnDelete {
	mutation := newTurnMutation(c.config, OpDelete)
	return &TurnDelete{config: c.config, hooks: c.Hooks(), mutation: mutation}
}

// DeleteOne returns a delete builder for the given entity.
func (c *TurnClient) DeleteOne(t *Turn) *TurnDeleteOne {
	return c.DeleteOneID(t.ID)
}

// DeleteOneID returns a delete builder for the given id.
func (c *TurnClient) DeleteOneID(id int) *TurnDeleteOne {
	builder := c.Delete().Where(turn.ID(id))
	builder.mutation.id = &id
	builder.mutation.op = OpDeleteOne
	return &TurnDeleteOne{builder}
}

// Query returns a query builder for Turn.
func (c *TurnClient) Query() *TurnQuery {
	return &TurnQuery{
		config: c.config,
	}
}

// Get returns a Turn entity by its id.
func (c *TurnClient) Get(ctx context.Context, id int) (*Turn, error) {
	return c.Query().Where(turn.ID(id)).Only(ctx)
}

// GetX is like Get, but panics if an error occurs.
func (c *TurnClient) GetX(ctx context.Context, id int) *Turn {
	obj, err := c.Get(ctx, id)
	if err != nil {
		panic(err)
	}
	return obj
}

// Hooks returns the client hooks.
func (c *TurnClient) Hooks() []Hook {
	return c.hooks.Turn
}