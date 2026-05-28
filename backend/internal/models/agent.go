package models

import "time"

type UserRole string

const (
	RoleFieldAgent          UserRole = "field_agent"
	RoleCooperativeManager  UserRole = "cooperative_manager"
	RoleAdmin               UserRole = "admin"
	RoleEnterprise          UserRole = "enterprise"
)

type Agent struct {
	ID            string    `json:"id" db:"id"`
	Name          string    `json:"name" db:"name"`
	PINHash       string    `json:"-" db:"pin_hash"`
	Region        string    `json:"region" db:"region"`
	CooperativeID string    `json:"cooperativeId" db:"cooperative_id"`
	Role          UserRole  `json:"role" db:"role"`
	Active        bool      `json:"active" db:"active"`
	LastActive    *time.Time `json:"lastActive,omitempty" db:"last_active"`
	CreatedAt     time.Time `json:"createdAt" db:"created_at"`
}
