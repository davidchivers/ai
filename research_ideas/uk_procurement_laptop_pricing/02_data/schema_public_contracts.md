# schema public contracts

## table: `public_contracts_notice`
- `notice_id` (string, primary id from source)
- `source` (enum: `contractsfinder`, `findatender`, `other`)
- `buyer_name` (string)
- `buyer_type` (enum: `central`, `local`, `nhs`, `other`)
- `award_date` (date)
- `start_date` (date, nullable)
- `end_date` (date, nullable)
- `contract_total_value_gbp` (float, nullable)
- `estimated_value_flag` (bool)
- `framework_flag` (bool)
- `framework_id` (string, nullable; e.g., `RM6098`)
- `lot` (string, nullable)
- `procedure_type` (string; open/restricted/framework call-off/direct award etc.)
- `bidder_count` (int, nullable)
- `location_text` (string, nullable)
- `attachment_urls` (json list)
- `attachment_parsed_flag` (bool)

## table: `public_contracts_line_items`
- `notice_id` (foreign key)
- `line_item_id` (string)
- `sku_text_raw` (string)
- `quantity` (float, nullable)
- `unit_price_gbp` (float, nullable)
- `price_is_net_vat` (bool, nullable)
- `warranty_years` (float, nullable)
- `service_bundle_flags` (json: imaging/security/deployment/support/etc.)
- `hardware_only_flag` (bool)
- `bundle_separable_flag` (bool)
- `parse_confidence` (float, 0-1)
- `parse_notes` (string, nullable)

## table: `attachments_registry`
- `notice_id` (foreign key)
- `attachment_url` (string)
- `local_path` (string)
- `file_type` (enum: `pdf`, `xlsx`, `docx`, `other`)
- `download_status` (enum)
- `parse_status` (enum)
- `checksum` (string)

## notes
- Preserve raw text and parse diagnostics for reproducibility.
- Do not force missing unit prices; keep null and document missingness.
