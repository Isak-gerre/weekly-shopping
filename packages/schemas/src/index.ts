import { z } from 'zod';

export const IngredientSchema = z.object({
  id: z.string().uuid().optional(),
  name: z.string().min(1),
  quantity: z.number().nonnegative(),
  unit: z.string().min(1),
  notes: z.string().optional(),
});

export const RecipeSchema = z.object({
  id: z.string().uuid().optional(),
  title: z.string().min(1),
  description: z.string().optional(),
  instructions: z.array(z.string()).default([]),
  servings: z.number().int().positive(),
  ingredients: z.array(IngredientSchema),
  tags: z.array(z.string()).default([]),
  subrecipeIds: z.array(z.string().uuid()).default([]),
});

export const MealPlanEntrySchema = z.object({
  recipeId: z.string().uuid(),
  plannedServings: z.number().int().positive(),
});

export const MealPlanSchema = z.object({
  id: z.string().uuid().optional(),
  familyId: z.string().uuid(),
  name: z.string().min(1),
  weekOf: z.string(),
  entries: z.array(MealPlanEntrySchema),
});

export type Ingredient = z.infer<typeof IngredientSchema>;
export type Recipe = z.infer<typeof RecipeSchema>;
export type MealPlanEntry = z.infer<typeof MealPlanEntrySchema>;
export type MealPlan = z.infer<typeof MealPlanSchema>;

