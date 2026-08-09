<script setup lang="ts">
/*
 * Grid container for FactCard. No behaviour of its own: the copy handling lives
 * in the card, scoped to its own subtree, so inline code anywhere else on the
 * site keeps behaving like inline code.
 */
</script>

<template>
  <div class="fact-deck"><slot /></div>
</template>

<style scoped>
/*
 * auto-fit rather than a fixed column count: the deck has five cards and the
 * sidebar eats most of the width on a laptop, so a hand-set three-column grid
 * would overflow there and leave a gap on a wide screen.
 */
.fact-deck {
  display: grid;
  gap: 16px;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  margin: 28px 0;
}
</style>
